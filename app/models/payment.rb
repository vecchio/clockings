class Payment < ActiveRecord::Base
  belongs_to :employee, primary_key: :finger, foreign_key: :finger

  scope :between, ->(s_date, e_date) { where(workday: s_date..e_date) }
end
