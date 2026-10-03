ActiveAdmin.register_page 'My Account' do
  menu parent: I18n.t('active_admin.menu.settings'),
       priority: 0,
       label: I18n.t('active_admin.menu.my_account')

  content title: I18n.t('active_admin.menu.my_account') do
    panel content_tag(:span,
                      telegram_panel_title,
                      class: 'inline-flex items-center gap-2'
                        ) do
      render('admin/telegram_status')
    end
  end

  page_action :disconnect_telegram, method: :delete do
    current_admin.update!(telegram_id: nil, telegram_username: nil)
    redirect_to admin_my_account_path, notice: t('active_admin.my_account.disconnected')
  end
end
