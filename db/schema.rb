# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150217122240) do

  create_table "clockings", force: true do |t|
    t.integer  "finger"
    t.string   "name"
    t.string   "surname"
    t.string   "direction", limit: 3
    t.datetime "clocking"
    t.date     "workday"
  end

  add_index "clockings", ["clocking"], name: "index_clockings_on_clocking", using: :btree
  add_index "clockings", ["finger", "clocking"], name: "index_clockings_on_finger_and_clocking", using: :btree
  add_index "clockings", ["workday"], name: "index_clockings_on_workday", using: :btree

  create_table "employees", force: true do |t|
    t.string   "name"
    t.string   "surname"
    t.integer  "sort"
    t.integer  "finger"
    t.string   "term",          limit: 1, default: "T"
    t.date     "employed_from"
    t.date     "employed_to"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "employees", ["finger"], name: "index_employees_on_finger", using: :btree
  add_index "employees", ["sort"], name: "index_employees_on_sort", using: :btree

  create_table "holidays", force: true do |t|
    t.string   "holiday"
    t.date     "holidate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "holidays", ["holidate"], name: "index_holidays_on_holidate", using: :btree
  add_index "holidays", ["holiday"], name: "index_holidays_on_holiday", using: :btree

  create_table "payments", force: true do |t|
    t.integer "finger"
    t.integer "entries"
    t.date    "workday"
    t.time    "duration"
    t.decimal "pay_duration", precision: 8, scale: 2
    t.boolean "night",                                default: false
    t.time    "arrive"
  end

  add_index "payments", ["finger"], name: "index_payments_on_finger", using: :btree

end
