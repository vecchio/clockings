class Employee < ActiveRecord::Base

  # has_many :clockings
  has_many :clockings,  primary_key: 'finger', foreign_key: 'finger'
  has_many :payments,   primary_key: 'finger', foreign_key: 'finger'

  scope :filtered,        ->(filter)  { where('name like :filter or surname like :filter', filter: "%#{filter}%") }
  scope :surname_start,   ->(letter)  { where('surname like :filter', filter: "#{letter}%") }
  scope :active,          ->          { where('employed_to >= :today', today: Date.today) }
  scope :use_in_payroll,  ->          { where(include_in_payroll: true) }

  before_create :record_date

  def fullname
    "#{name} #{surname}"
  end

  def long_finger
    "P#{finger.to_s.rjust(3, '0')}"
  end
  protected

  def record_date
    self.employed_from = Date.today
    self.employed_to = Date.today + 20.years
  end
end
