module Api
  module V1
    class AdminBlueprint < Blueprinter::Base
      identifier :id

      fields :email, :role
    end
  end
end
