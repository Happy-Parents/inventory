namespace :inventory do
  desc 'Import inventory data from data_source/inventory-state.csv into the DB. ' \
       'Override the file with CSV_PATH=/path/to.csv'
  task import: :environment do
    require 'csv'

    csv_path = ENV['CSV_PATH'] || Rails.root.join('data_source', 'inventory-state.csv')
    abort "CSV not found at #{csv_path}" unless File.exist?(csv_path)

    # --- CSV column headers (Ukrainian) ---------------------------------------
    H_BRAND        = 'ТМ'                 # trademark / brand
    H_MFR_NAME     = 'Назва виробника'    # manufacturer's product name
    H_SITE_NAME    = 'Назва на сайті'     # name shown on the website
    H_MFR_SKU      = 'Арт. зовн.'         # external article  -> manufacturer_sku
    H_SKU          = 'Арт. внутр.'        # internal article  -> sku
    H_QTY          = 'Кількість'          # quantity on hand
    H_CATEGORY     = 'Категорія'          # category
    H_PACKAGING    = 'Пакування'          # packaging condition
    H_SITE_STATUS  = 'Наявність на сайті' # website publish status
    H_LANGUAGE     = 'Мова'               # product language
    H_NOTES        = 'Нотатки'            # free-text notes
    H_WAREHOUSE    = 'Склад'              # warehouse

    # Source placeholder tokens that mean "not decided yet" -> treat as absent.
    PLACEHOLDERS = [ 'визначити', 'перевірити' ].freeze

    norm = ->(v) { v.to_s.strip.presence }

    # In-memory, Unicode-aware dedupe cache for the small lookup tables, so that
    # "tactic"/"Tactic" and "віммельбух"/"Віммельбух" collapse to one row.
    # Ruby's String#downcase handles Cyrillic; SQLite's lower() does not, so we
    # never rely on the DB for case-insensitive matching here.
    lookup_cache = { Brand => {}, Category => {}, Warehouse => {} }
    lookup_cache.each_key do |model|
      model.find_each { |rec| lookup_cache[model][rec.name.downcase] ||= rec }
    end

    find_lookup = lambda do |model, raw|
      name = norm.call(raw)
      return nil if name.nil? || PLACEHOLDERS.include?(name.downcase)

      lookup_cache[model][name.downcase] ||= model.create!(name: name)
    end

    map_language = lambda do |raw|
      v = norm.call(raw)&.downcase
      return :unknown if v.nil? || PLACEHOLDERS.include?(v)

      case v
      when /\Aукр/ then :ukrainian
      when /\Aрос/ then :russian
      when /\Aангл/ then :english
      else :unknown
      end
    end

    map_site_status = lambda do |raw|
      v = norm.call(raw)&.downcase
      return :needs_review if v.nil?

      case v
      when 'є'    then :published
      when 'нема' then :not_published
      else :needs_review # "перевірити", "перевірити на буплікацію ...", etc.
      end
    end

    # Returns [packaging_condition, damaged_quantity]. Any non-blank note (e.g.
    # "зіпсовано", "зіпсовано (3шт.)", "нема") means damaged; a number in the
    # text is the damaged count, otherwise assume the whole quantity is damaged.
    map_packaging = lambda do |raw, qty|
      v = norm.call(raw)
      return [ :ok, 0 ] if v.nil?

      count = v[/\d+/]&.to_i
      [ :damaged, count || qty ]
    end

    stats = Hash.new(0)
    warnings = []

    CSV.foreach(csv_path, headers: true).with_index(2) do |row, line|
      begin
        mfr_name = norm.call(row[H_MFR_NAME])
        if mfr_name.nil?
          stats[:skipped_no_name] += 1
          warnings << "line #{line}: no manufacturer name — row skipped"
          next
        end

        brand     = find_lookup.call(Brand, row[H_BRAND])
        category  = find_lookup.call(Category, row[H_CATEGORY])
        warehouse = find_lookup.call(Warehouse, row[H_WAREHOUSE])

        qty = row[H_QTY].to_i
        packaging_condition, damaged_qty = map_packaging.call(row[H_PACKAGING], qty)

        mfr_sku = norm.call(row[H_MFR_SKU])
        sku     = norm.call(row[H_SKU])

        # Idempotent on the identifying triple so re-running updates in place.
        product = Product.find_or_initialize_by(
          manufacturer_name: mfr_name,
          manufacturer_sku: mfr_sku,
          sku: sku
        )
        was_new = product.new_record?

        product.name                = norm.call(row[H_SITE_NAME])
        product.brand               = brand
        product.category            = category
        product.language            = map_language.call(row[H_LANGUAGE])
        product.site_status         = map_site_status.call(row[H_SITE_STATUS])
        product.packaging_condition = packaging_condition
        product.notes               = norm.call(row[H_NOTES])

        # A "є" row can't be published without name + hp_url (never in the CSV).
        # Downgrade to needs_review and record why, so no data is lost.
        if product.published? && !product.valid?
          reason = 'source marked available on site (є) but missing ' \
                   "#{[ product.errors.key?(:name) ? 'site name' : nil, 'hp_url' ].compact.join(' and ')}"
          product.site_status = :needs_review
          product.notes = [ product.notes, "[import] #{reason}" ].compact.join(' | ')
          stats[:downgraded_from_published] += 1
          warnings << "line #{line}: #{reason} — set to needs_review"
        end

        ActiveRecord::Base.transaction do
          product.save!
          stats[was_new ? :products_created : :products_updated] += 1

          if warehouse
            stock = product.stock_items.find_or_initialize_by(warehouse: warehouse)
            stock.quantity         = qty
            stock.damaged_quantity = damaged_qty
            stock.save!
            stats[:stock_items] += 1
          else
            stats[:products_without_warehouse] += 1
            warnings << "line #{line}: no warehouse — stock not recorded"
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        stats[:errors] += 1
        warnings << "line #{line}: #{e.record.class} invalid — #{e.record.errors.full_messages.join('; ')}"
      end
    end

    puts "\nInventory import complete (#{csv_path})"
    puts '-' * 60
    %i[products_created products_updated stock_items downgraded_from_published
       products_without_warehouse skipped_no_name errors].each do |k|
      puts format('  %-28s %d', k, stats[k])
    end
    puts "  #{Brand.count} brands, #{Category.count} categories, #{Warehouse.count} warehouses"

    if warnings.any?
      puts "\nWarnings (#{warnings.size}):"
      warnings.first(50).each { |w| puts "  - #{w}" }
      puts "  ... (#{warnings.size - 50} more)" if warnings.size > 50
    end
  end
end
