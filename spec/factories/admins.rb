FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "password" }
    role { :manager }

    trait :super_admin do
      role { :super_admin }
    end
  end
end
