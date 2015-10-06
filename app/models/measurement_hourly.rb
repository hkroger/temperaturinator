# -*- encoding : utf-8 -*-
class MeasurementHourly < CassandraModel

  def self.get_range(location_id, start_time, end_time)
    year_months = (start_time.to_i..(end_time + 1.day).to_i).step(1.day).map { |t| "'" + ts_to_year_month(Time.at(t)) + "'" }.uniq

    cql = "SELECT hour as timestamp, temperature_count, temperature_sum_in_cents FROM measurements_hourly_avg WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")}) AND hour >= '#{start_time.to_s}' AND hour <= '#{end_time.to_s}'"
    results = execute_cql(cql)
  end
end
