class AddIncludeInPayrollToEpmployees < ActiveRecord::Migration
  def change
    add_column :employees, :include_in_payroll, :boolean, default: true
  end
end
