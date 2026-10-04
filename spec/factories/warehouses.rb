FactoryBot.define do
  factory :warehouse do
    sequence(:name) { |n| "#{Faker::Address.city} Warehouse #{n}" }
  end
end
