# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_28_120005) do
  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brands_on_name", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "parent_id"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "brand_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.string "hp_url"
    t.string "language", default: "unknown", null: false
    t.string "manufacturer_name", null: false
    t.string "manufacturer_sku"
    t.string "name"
    t.text "notes"
    t.string "packaging_condition", default: "ok", null: false
    t.string "site_status", default: "needs_review", null: false
    t.string "sku"
    t.datetime "updated_at", null: false
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["manufacturer_sku"], name: "index_products_on_manufacturer_sku"
    t.index ["sku"], name: "index_products_on_sku"
  end

  create_table "stock_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "damaged_quantity", default: 0, null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "warehouse_id", null: false
    t.index ["product_id", "warehouse_id"], name: "index_stock_items_on_product_id_and_warehouse_id", unique: true
    t.index ["product_id"], name: "index_stock_items_on_product_id"
    t.index ["warehouse_id"], name: "index_stock_items_on_warehouse_id"
  end

  create_table "warehouses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_warehouses_on_name", unique: true
  end

  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
  add_foreign_key "stock_items", "products"
  add_foreign_key "stock_items", "warehouses"
end
