FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "#{FFaker::Company.name} #{n}" }
  end
end
