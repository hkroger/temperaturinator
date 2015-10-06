# -*- encoding : utf-8 -*-
class MeasurementDaily < CassandraModel

  def self.get_range(location_id, start_time, end_time)
    year_months = (start_time.to_i..(end_time + 1.day).to_i).step(1.day).map { |t| "'" + ts_to_year_month(Time.at(t)) + "'" }.uniq

    cql = "SELECT day as timestamp, temperature_count, temperature_sum_in_cents FROM measurements_daily_avg WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")}) AND day >= '#{start_time.to_date.to_s} 00:00:00' AND day <= '#{end_time.to_date.to_s} 00:00:00'"
    results = execute_cql(cql)
  end

  def self.get_min_max(location_id, start_time, end_time)
    year_months = (start_time.to_i..(end_time + 1.day).to_i).step(1.day).map { |t| "'" + ts_to_year_month(Time.at(t)) + "'" }.uniq

    cql = "SELECT day, min, max FROM measurements_daily_min_max WHERE location_id = #{location_id} AND "+
      "day >= '#{start_time.to_date.to_s} 00:00:00' AND day <= '#{end_time.to_date.to_s} 00:00:00'"
    results = execute_cql(cql)

    minmax = {min: [], max: []}
    results.each do |res|
      minmax[:min] << [res['day'].localtime.to_i*1000, res['min'].to_f.round(2)]
      minmax[:max] << [res['day'].localtime.to_i*1000, res['max'].to_f.round(2)]
    end
    minmax
  end
end
