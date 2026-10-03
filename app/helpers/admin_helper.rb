module AdminHelper
  def product_name_and_sku(product)
    name = product.manufacturer_name.presence || product.name || '–'
    sku  = product.manufacturer_sku.presence || product.sku || '–'
    "#{name}(#{sku})"
  end

  def telegram_panel_title
    safe_join([
      render('admin/telegram_logo'),
      t('active_admin.my_account.telegram_panel')
    ]
    )
  end
end
