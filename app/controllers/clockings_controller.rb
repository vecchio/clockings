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
      system('sh sql/import-mysql.sh') ? flash[:notice] = 'Data successfully imported' : flash[:error] =  'Data import failed ! ! !'
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
