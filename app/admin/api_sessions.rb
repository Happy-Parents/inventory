ActiveAdmin.register ApiSession do
  menu parent: I18n.t('active_admin.menu.settings'),
       priority: 3,
       label: I18n.t('active_admin.menu.api_sessions')
  actions :index, :destroy
  config.sort_order = 'updated_at_desc'

  index title: I18n.t('active_admin.menu.api_sessions'), download_links: false do
    selectable_column

    column :admin
    column :provider
    column :device_name
    column :created_at
    column :updated_at
    column :expires_at

    actions
  end

  filter :admin, as: :select, collection: -> { Admin.where(id: ApiSession.active.select(:admin_id)).order(:email).pluck(:email, :id) }
  filter :provider, as: :select, collection: -> { ApiSession.active.distinct.order(:provider).pluck(:provider) }
  filter :device_name

  controller do
    def scoped_collection = super.active.includes(:admin)

    def destroy_resource(api_session) = ApiSessions::Revoke.call(api_session)
  end
end
