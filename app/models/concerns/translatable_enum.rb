module TranslatableEnum
  extend ActiveSupport::Concern

  class_methods do
    def human_enum(enum, value)
      return if value.nil?

      I18n.t(value, scope: [ :activerecord, :enums, model_name.i18n_key, enum ],
                    default: value.to_s.humanize)
    end

    def enum_options(enum)
      public_send(enum.to_s.pluralize).keys.map { |key| [ human_enum(enum, key), key ] }
    end
  end
end
