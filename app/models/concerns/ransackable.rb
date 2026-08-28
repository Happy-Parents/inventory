# Provides Ransack's required allowlists (used by ActiveAdmin filters)
module Ransackable
  extend ActiveSupport::Concern

  class_methods do
    def unransackable_attributes
      []
    end

    def ransackable_attributes(_auth_object = nil)
      column_names - unransackable_attributes
    end

    def ransackable_associations(_auth_object = nil)
      reflect_on_all_associations.map { |association| association.name.to_s }
    end
  end
end
