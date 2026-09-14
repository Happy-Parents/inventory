FactoryBot.define do
  factory :warehouse do
    sequence(:name) { |n| "#{FFaker::Address.city} Warehouse #{n}" }
  end
end
