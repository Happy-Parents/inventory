# ActiveAdmin authorization rules:
#   * super_admin — may manage everything, including Admin records.
#   * manager     — may manage everything EXCEPT Admin records, but may still
#     view their own profile.
# Anything that isn't an Admin (products, brands, dashboard, comments, ...) is
# open to any signed-in admin; Admin is restricted to super_admins.
class InventoryAuthorization < ActiveAdmin::AuthorizationAdapter
  def authorized?(action, subject = nil)
    if admin_subject?(subject)
      user&.super_admin? || own_profile_read?(action, subject)
    else
      true
    end
  end

  private

  def admin_subject?(subject)
    subject == Admin || subject.is_a?(Admin)
  end

  def own_profile_read?(action, subject)
    action == ActiveAdmin::Auth::READ && subject == user
  end
end
