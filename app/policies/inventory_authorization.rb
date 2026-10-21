# ActiveAdmin authorization rules:
#   * super_admin — may manage everything, including Admin records and API
#     sessions.
#   * manager     — may manage everything EXCEPT Admin records and API
#     sessions, but may still view their own profile.
# Anything else (products, brands, dashboard, comments, ...) is open to any
# signed-in admin.
class InventoryAuthorization < ActiveAdmin::AuthorizationAdapter
  SUPER_ADMIN_ONLY = [ Admin, ApiSession ].freeze

  def authorized?(action, subject = nil)
    if super_admin_only?(subject)
      user&.super_admin? || own_profile_read?(action, subject)
    else
      true
    end
  end

  private

  def super_admin_only?(subject)
    SUPER_ADMIN_ONLY.any? { |klass| subject == klass || subject.is_a?(klass) }
  end

  def own_profile_read?(action, subject)
    action == ActiveAdmin::Auth::READ && subject == user
  end
end
