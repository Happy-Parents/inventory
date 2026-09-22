FactoryBot.define do
  factory :stock_item do
    product
    warehouse
    quantity { rand(1..100) }
    damaged_quantity { 0 }

    trait :damaged do
      damaged_quantity { rand(1..10) }
    end
  end
end
