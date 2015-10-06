require 'csv'

# -*- encoding : utf-8 -*-
class LogsController < AuthorizedController

  def index
    @location = Location.find_by_id(params[:location]) || Location.first
    @from_date = get_date(:from_date)
    @to_date = get_date(:to_date)

    if params[:commit] == 'Load CSV'
      dump_csv
    else
      @log_entries = Measurement.find_all(@location.id, @from_date, @to_date + 1.days)
    end
  end

  private 
  def get_date(date_field)
    if params[date_field].presence
      [Date.today.to_time, Time.strptime(params[date_field],"%Y-%m-%d")].min
    else
      Date.today.to_time
    end
  end

  def dump_csv
    file_name = "temperatures #{@location.description} #{@from_date.to_date} - #{@to_date.to_date}.csv"
    headers["Content-Type"] = "text/csv"
    headers["Content-disposition"] = "attachment; filename=\"#{file_name}\""
    #nginx doc: Setting this to "no" will allow unbuffered responses suitable for Comet and HTTP streaming applications
    headers['X-Accel-Buffering'] = 'no'
    
    headers["Cache-Control"] ||= "no-cache"
    headers.delete("Content-Length")
    self.response_body = csv_lines
  end

  def csv_lines
    Enumerator.new do |e|
      e << ['Time', 'Measurement (°C)', 'Voltage (V)', 'Signal strength (Dbm)'].to_csv
      Measurement.for_each(@location.id, @from_date, @to_date + 1.days) { |t| e << [t.timestamp, t.measurement, t.voltage, t.signal_strength].to_csv }
    end
  end
end
