class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def get_param_dates
    if params[:s_date].present?
      @s_date = Date.strptime(params[:s_date], '%d %B %Y')
      @e_date = Date.strptime(params[:e_date], '%d %B %Y') if params[:e_date].present?
      @e_date = @s_date unless @e_date.present?
    end
    @s_date ||= Date.today.beginning_of_week(:wednesday)
    @e_date ||= @s_date + 7.days
  end

end
