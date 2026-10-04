FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{Faker::Commerce.brand} #{n}" }

    trait :with_parent do
      association :parent, factory: :category
    end
  end
end
