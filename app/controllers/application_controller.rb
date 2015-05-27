class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def get_param_dates
    if params[:filter].present?
      filter  = params[:filter]
      @s_date = convert_date(filter['s_date(1i)'], filter['s_date(2i)'], filter['s_date(3i)'])
      @e_date = convert_date(filter['e_date(1i)'], filter['e_date(2i)'], filter['e_date(3i)']) if filter['e_date(1i)'].present?
      @e_date = @s_date unless @e_date.present?
    end
    @s_date ||= Date.today.beginning_of_week(:friday)
    @e_date ||= @s_date + 7.days
  end

  def convert_date(year, month, day)
    Date.new(year.to_i, month.to_i, day.to_i)
  end
end
