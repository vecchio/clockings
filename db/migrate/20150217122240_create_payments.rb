class CreatePayments < ActiveRecord::Migration
  def change

    create_table :payments do |t|
      t.integer :finger
      t.integer :entries
      t.date :workday
      t.time :duration
      t.decimal :pay_duration, :precision => 8, :scale => 2
      t.boolean :night, default: false
      t.time :arrive
    end
    add_index :payments, :finger
  end
end
