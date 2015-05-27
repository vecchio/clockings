class CreateHolidays < ActiveRecord::Migration
  def change
    create_table :holidays do |t|
      t.string :holiday
      t.date :holidate

      t.timestamps
    end
    add_index :holidays, :holiday
    add_index :holidays, :holidate
  end
end
