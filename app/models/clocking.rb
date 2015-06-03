require 'csv'
class Clocking < ActiveRecord::Base
  belongs_to :employee, primary_key: :finger, foreign_key: :finger

  scope :between, ->(s_date, e_date) { where(workday: s_date..e_date) }

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |r|
    # CSV.foreach(file.path) do |r|
      row =  r.to_hash
      unless Clocking.exists?(finger: row['EmpNo'], clocking: row['DateTime'].to_datetime)
        wd = row['DateTime'].to_date
        wd = wd - 1.day if row['DateTime'].to_datetime.hour >= 0 && row['DateTime'].to_datetime.hour < 5
        Clocking.create!(finger:    row['EmpNo'],
                         clocking:  row['DateTime'].to_datetime,
                         name:      row['Name'],
                         surname:   row['Surname'],
                         direction: row['IN/Out Button'],
                         workday:   row['DateTime'].to_date )
      end
    end

  end
end
