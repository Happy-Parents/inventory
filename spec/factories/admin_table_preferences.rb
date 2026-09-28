FactoryBot.define do
  factory :admin_table_preference do
    admin
    resource_key { 'products' }
    visible_columns { %w[brand sku] }
  end
end
