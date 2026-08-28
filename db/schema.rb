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

ActiveRecord::Schema[8.1].define(version: 2026_08_28_124359) do
  create_table "active_admin_comments", force: :cascade do |t|
    t.integer "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

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
