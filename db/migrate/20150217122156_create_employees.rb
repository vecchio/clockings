class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.string :name
      t.string :surname
      t.integer :sort
      t.integer :finger
      t.string :term, limit: 1, default: 'T'
      t.date :employed_from
      t.date :employed_to

      t.timestamps
    end
    add_index :employees, :sort
    add_index :employees, :finger
  end
end
