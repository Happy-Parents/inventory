module AdminHelper
  def product_name_and_sku(product)
    name = product.manufacturer_name.presence || product.name || '–'
    sku  = product.manufacturer_sku.presence || product.sku || '–'
    "#{name}(#{sku})"
  end
end
