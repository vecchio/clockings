class CreateClockings < ActiveRecord::Migration
  def change

    create_table :clockings do |t|
      t.integer :finger
      t.string  :name
      t.string  :surname
      t.string  :direction, limit: 3
      t.timestamp :clocking
      t.date :workday
    end
    add_index :clockings, [:finger, :clocking]
    add_index :clockings, :clocking
    add_index :clockings, :workday
  end
end
