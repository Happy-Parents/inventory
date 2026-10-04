FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| Faker::Internet.email(name: "admin#{n}") }
    password { "password" }
    role { :manager }

    trait :super_admin do
      role { :super_admin }
    end
  end
end
