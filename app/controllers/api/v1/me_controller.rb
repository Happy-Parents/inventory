module Api
  module V1
    class MeController < BaseController
      def show
        authorize current_admin

        render json: AdminBlueprint.render_as_hash(current_admin)
      end
    end
  end
end
