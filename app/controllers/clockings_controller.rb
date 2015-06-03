class ClockingsController < ApplicationController
  before_action :set_clocking, only: [:show, :edit, :update, :destroy]

  # GET /clockings
  # GET /clockings.json
  def index
    @workday = params[:workday].to_date
    @employee  = Employee.where(finger: params[:finger]).first
    @clockings = Clocking.where(finger: params[:finger], workday: @workday).order(:clocking).all


    @in_out = []
    i_time = Date.today.beginning_of_day
    last_direction = ''

    @clockings.each do | c |
       unless last_direction == c.direction.strip
          last_direction = c.direction.strip
          if c.direction.strip == 'in'
            i_time = c.clocking
          else
            @in_out << [i_time, c.clocking] if c.direction.strip == 'out'
          end
       end
    end

    respond_to do |format|
      format.html
      format.pdf {
        html = render_to_string(action: 'index.html.slim', layout: 'pdf.html.slim')
        kit = PDFKit.new(html)
        kit.stylesheets << "#{Rails.root.join('app/assets/stylesheets','pdf.css')}"
        send_data kit.to_pdf, :filename => 'clockings.pdf', :type => :pdf
      }
    end



  end

  # GET /clockings/1
  # GET /clockings/1.json
  def show
  end

  # GET /clockings/new
  def new
    @clocking = Clocking.new
  end

  # GET /clockings/1/edit
  def edit
  end

  def get_import
  end

  def import
    if params[:file].present?
      Clocking.import(params[:file])
      # system('sh sql/import-mysql.sh') ? flash[:notice] = 'Data successfully imported' : flash[:error] =  'Data import failed ! ! !'

      sql = <<-SQL
                  drop table if exists tmp_daterange;
                  drop table if exists tmp_clockinout;
                  drop table if exists tmp_clockinoutclean_o;
                  drop table if exists tmp_clockinoutclean;
                  drop table if exists tmp_clockinoutduration;
                  drop table if exists tmp_clockempday;

                  create temporary table tmp_daterange as
                    select max(workday) as s_date, current_date as e_date from payments;
                  update tmp_daterange set e_date = date_add(s_date, interval 50 day);
                  delete from payments where workday >= (select s_date from tmp_daterange );

                  create temporary table tmp_clockinout as
                    select i.finger, i.name, i.surname, i.workday, i.direction as idir, i.clocking as iclock, o.direction as odir, o.clocking as oclock
                    from clockings i, clockings o, tmp_daterange d
                    where i.workday between  d.s_date and d.e_date
                          and o.workday between  d.s_date and d.e_date
                          and i.finger = o.finger
                          and i.workday = o.workday
                          and i.direction = 'in'
                          and o.direction = 'out'
                          and o.clocking  > i.clocking
                    order by finger, iclock, oclock;

                  delete from tmp_clockinout where oclock <  iclock;

                  create temporary table tmp_clockinoutclean_o as
                    select finger, name, surname, workday, idir, iclock, odir, min(oclock) as oclock
                    from tmp_clockinout
                    group by finger, name, surname, workday, idir, iclock, odir
                    order by finger, iclock, oclock;

                  create temporary table tmp_clockinoutclean as
                    select finger, name, surname, workday, idir, min(iclock) as iclock, odir, oclock
                    from tmp_clockinoutclean_o
                    group by finger, name, surname, workday, idir, oclock, odir
                    order by finger, iclock, oclock;

                  create temporary table tmp_clockinoutduration as
                    select *, time_to_sec(timediff(oclock,iclock)) as dur
                    from tmp_clockinoutclean
                    order by finger, iclock;

                  create temporary table tmp_clockempday as
                    select  finger, name, surname, workday,
                      sec_to_time(sum(dur)) as dur, count(1) as entries, cast(0 as decimal(8,2)) as pay,
                      case when extract(hour from min(iclock)) >= 16 and extract(minute from min(Iclock)) >= 15
                        then 1 else 0
                      end as night,
                      time(min(iclock)) as arrive
                    from tmp_clockinoutduration
                    group by finger, name, surname, workday
                    order by finger, workday;

                  update tmp_clockempday set pay = cast((((extract(hour from dur) * 60) + (extract(minute from dur) + 50))/60) as decimal(8,2));
                  update tmp_clockempday set pay = truncate(pay, 0) 	where (pay - truncate(pay, 0)) between 0.0 and 0.11;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 0.25)  where (pay - truncate(pay, 0)) between 0.12 and 0.25;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 0.25)  where (pay - truncate(pay, 0)) between 0.26 and 0.36;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 0.5) 	where (pay - truncate(pay, 0)) between 0.37 and 0.5;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 0.5) 	where (pay - truncate(pay, 0)) between 0.51 and 0.61;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 0.75)  where (pay - truncate(pay, 0)) between 0.62 and 0.75;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 0.75)  where (pay - truncate(pay, 0)) between 0.76 and 0.86;
                  update tmp_clockempday set pay = (truncate(pay, 0)+ 1.00)  where (pay - truncate(pay, 0)) > 0.86;
                  insert into payments (finger, pay_duration, workday, duration, entries, night, arrive)
                    select finger, pay, workday, dur, entries, night, arrive from tmp_clockempday;

      SQL

      sql.split(';').each do |s|
        ActiveRecord::Base.connection.execute(s) if s.present?
      end

      redirect_to day_employees_path, notice: 'Clockings imported.'
    else
      redirect_to get_import_clockings_path, alert: 'Please provide a file to upload ! ! !'
    end
  end

  # POST /clockings
  # POST /clockings.json
  def create
    @clocking = Clocking.new(clocking_params)

    respond_to do |format|
      if @clocking.save
        format.html { redirect_to @clocking, notice: 'Clocking was successfully created.' }
        format.json { render :show, status: :created, location: @clocking }
      else
        format.html { render :new }
        format.json { render json: @clocking.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clockings/1
  # PATCH/PUT /clockings/1.json
  def update
    respond_to do |format|
      if @clocking.update(clocking_params)
        format.html { redirect_to @clocking, notice: 'Clocking was successfully updated.' }
        format.json { render :show, status: :ok, location: @clocking }
      else
        format.html { render :edit }
        format.json { render json: @clocking.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /clockings/1
  # DELETE /clockings/1.json
  def destroy
    @clocking.destroy
    respond_to do |format|
      format.html { redirect_to clockings_url, notice: 'Clocking was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_clocking
      @clocking = Clocking.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def clocking_params
      params.require(:clocking).permit(:finger, :direction, :clocking, :workday)
    end
end
