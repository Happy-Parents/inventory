FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
  end
end
