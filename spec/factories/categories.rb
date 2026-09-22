FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{FFaker::Product.brand} #{n}" }

    trait :with_parent do
      association :parent, factory: :category
    end
  end
end
