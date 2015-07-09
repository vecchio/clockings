require 'csv'
class Clocking < ActiveRecord::Base
  belongs_to :employee, primary_key: :finger, foreign_key: :finger

  scope :between, ->(s_date, e_date) { where(workday: s_date..e_date) }

  def self.import(file)
    earliest_clocking = Time.now + 1.year
    CSV.foreach(file.path, headers: true) do |r|
      row =  r.to_hash
      clocking = row['DateTime'].to_datetime
      unless Clocking.exists?(finger: row['EmpNo'], clocking: row['DateTime'].to_datetime)
        workday  = clocking.to_date
        workday  = workday - 1.day if row['DateTime'].to_datetime.hour >= 0 && row['DateTime'].to_datetime.hour < 5
        Clocking.create!(finger:    row['EmpNo'],
                         clocking:  clocking,
                         name:      row['Name'],
                         surname:   row['Surname'],
                         direction: row['IN/Out Button'],
                         workday:   workday )
      end
      earliest_clocking = clocking if clocking < earliest_clocking
    end

    Clocking.where('clocking >= ?', earliest_clocking).order(:finger).select(:finger, :name, :surname).uniq.each do |c|
      unless Employee.exists?(finger: c.finger)
        Employee.create!(finger:    c.finger,
                         name:      c.name,
                         surname:   c.surname)
      end
    end

  end
end
