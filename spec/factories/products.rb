FactoryBot.define do
  factory :product do
    manufacturer_name { Faker::Commerce.product_name }
    name { Faker::Commerce.product_name }
    sequence(:sku) { |n| "SKU-#{n}" }
    sequence(:manufacturer_sku) { |n| "MSKU-#{n}" }
    hp_url { Faker::Internet.url }
    notes { Faker::Lorem.sentence }
    language { :unknown }
    site_status { :needs_review }
    packaging_condition { :ok }

    trait :published do
      site_status { :published }
    end

    trait :with_brand do
      brand
    end

    trait :with_category do
      category
    end
  end
end
