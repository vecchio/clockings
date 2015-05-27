class ClockingsController < ApplicationController
  before_action :set_clocking, only: [:show, :edit, :update, :destroy]

  # GET /clockings
  # GET /clockings.json
  def index
    @workday = params[:workday].to_date
    @employee  = Employee.where(finger: params[:finger]).first
    @clockings = Clocking.where(finger: params[:finger], workday: @workday).order(:clocking).all
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