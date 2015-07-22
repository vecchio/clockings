require 'csv'
class EmployeesController < ApplicationController
  before_action :set_employee, only: [:show, :edit, :update, :destroy]

  # GET /employees
  # GET /employees.json
  def index
    @employees = Employee.all
  end

  def import
    system('sh sql/import-mysql.sh') ? flash[:notice] = 'Data successfully imported' : flash[:error] =  'Data import failed ! ! !'
    redirect_to filter_employees_path
  end

  def filter
    @employees = Employee.order(:surname)
    @employees = @employees.active                                  unless params[:show_all]
    @employees = @employees.use_in_payroll                          if params[:payroll]
    @employees = @employees.filtered(params[:q])                    if params[:q].present?
    @employees = @employees.surname_start(params['surname_start'])  if params[:surname_start]
    @employees = @employees.limit(50)                               unless params[:filter] || params[:surname_start]
    @employees = @employees.all
  end

  def day
    get_param_dates

    @payments = Payment.joins(:employee)
    # @payments = @payments.active unless params[:show_all]
    @payments = @payments.between(@s_date, @s_date)
    @payments = @payments.merge(Employee.filtered(params[:q]))                    if params[:q].present?
    @payments = @payments.merge(Employee.surname_start(params['surname_start']))  if params[:surname_start]
    @payments = @payments.merge(Employee.active)                                  unless params[:show_all]
    @payments = @payments.merge(Employee.use_in_payroll)                          if params[:payroll]

    sql = <<-SQL
                  sum(case
                      when employees.term = 'P'
                      then 1 else 0 end) as perms,
                  sum(case
                      when employees.term = 'T'
                      then 1 else 0 end) as temps,
                  sum(case
                        when extract(hour from arrive) > 5 and extract(hour from arrive) < 16 then
                          case
                            when extract(hour from arrive) < 7 then 0
                            when extract(hour from arrive) = 7 and extract(minute from arrive) < 15 then 0
                            else 1
                          end

                        when extract(hour from arrive) >= 16 then
                          case
                            when extract(hour from arrive) = 16 and extract(minute from arrive) <= 30
                            then 0
                            else 1
                          end
                      end) as late
          SQL

    @totals   = @payments.select(sql)

    sql = <<-SQL
                  payments.*,
                  case
                      when extract(hour from arrive) > 5 and extract(hour from arrive) < 16 then
                        case
                          when extract(hour from arrive) < 7 then 0
                          when extract(hour from arrive) = 7 and extract(minute from arrive) < 15 then 0
                          else 1
                        end

                      when extract(hour from arrive) >= 16 then
                        case
                          when extract(hour from arrive) = 16 and extract(minute from arrive) <= 30
                          then 0
                          else 1
                        end
                  end as late
    SQL

    @payments = @payments.select(sql)
    @payments = @payments.limit(100)                                              unless params[:filter] || params[:surname_start]
    @payments = @payments.order(:workday, :finger).all

    respond_to do |format|
      format.html
      format.pdf {
        html = render_to_string(action: 'day.html.slim', layout: 'pdf.html.slim')
        kit = PDFKit.new(html)
        kit.stylesheets << "#{Rails.root.join('app/assets/stylesheets','pdf.css')}"
        send_data kit.to_pdf, :filename => 'day-clockings.pdf', :type => :pdf
      }
    end
  end

  # GET /employees/1
  # GET /employees/1.json
  def show
  end

  # GET /employees/new
  def new
    @employee = Employee.new
    @employee.employed_from = Date.today
    @employee.employed_to = Date.today + 35.years
  end

  # GET /employees/1/edit
  def edit
  end

  # POST /employees
  # POST /employees.json
  def create
    @employee = Employee.new(employee_params)


    respond_to do |format|
      if @employee.save
        format.html { redirect_to @employee, notice: 'Employee was successfully created.' }
        format.json { render :show, status: :created, location: @employee }
      else
        format.html { render :new }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /employees/1
  # PATCH/PUT /employees/1.json
  def update
    respond_to do |format|
      if @employee.update(employee_params)
        format.html { redirect_to filter_employees_path, notice: 'Employee was successfully updated.' }
        format.json { render :show, status: :ok, location: @employee }
      else
        format.html { render :edit }
        format.json { render json: @employee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /employees/1
  # DELETE /employees/1.json
  def destroy
    @employee.destroy
    respond_to do |format|
      format.html { redirect_to filter_employees_path, notice: 'Employee was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def payroll_export
    s_date = params[:s_date].to_date
    e_date = params[:e_date].to_date
    payroll_query(s_date, e_date)


    csv_string = CSV.generate do |csv|
      csv << %w(no roses name surname wed thu fri mon tue tot sat sun pub)
      @payroll.each do |p|
        csv << [p.sort,"P#{p.finger.to_s.rjust(3, '0')}",p.name,p.surname,p.wed,p.thu,p.fri,p.mon,p.tue,(p.wed+p.thu+p.fri+p.mon+p.tue),p.sat,p.sun,p.pub]
      end
    end
    csv_string.gsub!(/\n/, "\r\n")

    send_data csv_string,
              :type => 'text/csv; charset=iso-8859-1; header=absent',
              :disposition => "attachment; filename=payroll_export_#{s_date.strftime('%d%b%Y')}-to-#{e_date.strftime('%d%b%Y')}.csv"
  end

  def payroll
    get_param_dates
    payroll_query(@s_date, @e_date)

    # if params[:export]
    #   redirect_to action: :payroll_export, s_date: @s_date, e_date: @e_date
    # end

    respond_to do |format|
      format.html
      format.csv {
        redirect_to action: :payroll_export, s_date: @s_date, e_date: @e_date
      }
    end

  end

  private

    def payroll_query(s_date, e_date)
      sql = <<-SQL
                    employees.sort, employees.finger, employees.name, employees.surname, employees.term,
                    sum(case
                        when dayofweek(workday) = 1  and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as sun,
                    sum(case
                        when dayofweek(workday) = 2 and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as mon,
                    sum(case
                        when dayofweek(workday) = 3  and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as tue    ,
                    sum(case
                        when dayofweek(workday) = 4  and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as wed   ,
                    sum(case
                        when dayofweek(workday) = 5  and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as thu,
                    sum(case
                        when dayofweek(workday) = 6  and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as fri,
                    sum(case
                        when dayofweek(workday) = 7  and holidate is null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as sat,
                    sum(case
                        when holidate is not null
                        then ifnull(pay_duration, 0)                      else 0
                        end) as pub,
                    sum(1) as records
      SQL

      join_payroll = "left join payments on payments.finger = employees.finger and payments.workday between '#{@s_date}' AND '#{@s_date}'"
      @payroll = Employee.joins(join_payroll) if params[:show_all].present?
      @payroll = Employee.use_in_payroll.joins(join_payroll) unless params[:show_all].present?
      @payroll = @payroll.joins('left join holidays on workday = holidate')
      @payroll = @payroll.select(sql)
      @payroll = @payroll.group('employees.sort, employees.finger, employees.name, employees.surname, employees.term')
      @payroll = @payroll.order('employees.sort')
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_employee
      @employee = Employee.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def employee_params
      params.require(:employee).permit(:name, :surname, :sort, :finger, :filter, :term, :include_in_payroll, :employed_from, :employed_to)
    end
end
