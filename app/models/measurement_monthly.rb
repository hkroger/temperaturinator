# -*- encoding : utf-8 -*-
class MeasurementMonthly < CassandraModel

  def self.get_range(location_id, start_time, end_time)
    year_months = (start_time.to_i..(end_time + 1.day).to_i).step(1.day).map { |t| "'" + ts_to_year_month(Time.at(t)) + "'" }.uniq

    cql = "SELECT year_month as timestamp, temperature_count, temperature_sum_in_cents FROM measurements_monthly_avg WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")})"
    results = execute_cql(cql)
  end

  def self.get_min_max(location_id, start_time, end_time)
    year_months = (start_time.to_i..(end_time + 1.day).to_i).step(1.day).map { |t| "'" + ts_to_year_month(Time.at(t)) + "'" }.uniq

    cql = "SELECT year_month, min, max FROM measurements_monthly_min_max WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")})"
    results = execute_cql(cql)

    minmax = {min: [], max: []}
    results.each do |res|
      minmax[:min] << [year_month_to_ts(res['year_month']).localtime.to_i*1000, res['min'].to_f.round(2)]
      minmax[:max] << [year_month_to_ts(res['year_month']).localtime.to_i*1000, res['max'].to_f.round(2)]
    end
    minmax
  end
end
