# -*- encoding : utf-8 -*- 
class Measurement < CassandraModel
  def self.fields 
    %w(location_id year_month id measurement voltage signal_strength) 
  end 

  def self.table_name
    "measurements"
  end

  def timestamp
    id.to_time
  end

  def self.for_each(location_id, start_time, end_time, &code)
    year_months = year_months_from_dates(start_time, end_time)

    cql = "SELECT id, measurement, voltage, signal_strength FROM #{table_name} WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")}) AND id >= minTimeuuid('#{start_time.to_s}') AND id <= maxTimeuuid('#{end_time.to_s}')"

    result = execute_paged_cql(cql, 1000)
    
    loop do
      result.each{ |row| yield new(row, true) }
      break if result.last_page?
      result = result.next_page
    end
  end

  def self.find_all(location_id, start_time, end_time)
    year_months = year_months_from_dates(start_time, end_time)

    cql = "SELECT id, measurement, voltage, signal_strength FROM #{table_name} WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")}) AND id >= minTimeuuid('#{start_time.to_s}') AND id <= maxTimeuuid('#{end_time.to_s}')"

    execute_cql(cql).map { |row| new(row, true) }
  end

  def self.get_range(location_id, start_time, end_time)
    year_months = year_months_from_dates(start_time, end_time)

    cql = "SELECT dateof(id) as timestamp, measurement FROM #{table_name} WHERE location_id = #{location_id} AND "+
      "year_month IN (#{year_months.join(",")}) AND id >= minTimeuuid('#{start_time.to_s}') AND id <= maxTimeuuid('#{end_time.to_s}')"

    execute_cql(cql)
  end

  def update_all_stats(now)
    hour = to_hour_stamp(now)
    day = to_day_stamp(now)
    update_stats(now)
    tmp_in_cents = (measurement * 100).round
    cnt_update = "temperature_count = temperature_count+1, temperature_sum_in_cents = temperature_sum_in_cents + #{tmp_in_cents}"

    cql = "UPDATE measurements_hourly_avg SET #{cnt_update} WHERE location_id = #{location_id} AND year_month = '#{year_month}' AND hour = '#{hour}'"
    execute_cql(cql)

    cql = "UPDATE measurements_daily_avg SET #{cnt_update} WHERE location_id = #{location_id} AND year_month = '#{year_month}' AND day = '#{day}'"
    execute_cql(cql)

    cql = "UPDATE measurements_monthly_avg SET #{cnt_update} WHERE location_id = #{location_id} AND year_month = '#{year_month}'"
    execute_cql(cql)
  end

  private
  def update_min_max(ts, full_table, condition_string, row=nil)
    if row.nil?
      cql = "SELECT min,max from #{full_table} WHERE #{condition_string}"
      row = execute_cql(cql).first
    end
    if row.nil? || row["max"].nil? || row["max"] < measurement
      cql = "UPDATE #{full_table} SET max=#{measurement}, max_at='#{ts_to_cassandra(ts)}' WHERE #{condition_string}"
      execute_cql(cql)
    end

    if row.nil? || row["min"].nil? || row["min"] > measurement
      cql = "UPDATE #{full_table} SET min=#{measurement}, min_at='#{ts_to_cassandra(ts)}' WHERE #{condition_string}"
      execute_cql(cql)
    end
  end

  def update_stats(ts)
    cql = "SELECT first_read_at, min, max from measurements_stats WHERE location_id = #{location_id}"
    stats = execute_cql(cql).first
    update_min_max(ts, "measurements_stats", "location_id = #{location_id}", stats)
    update_min_max(ts, "measurements_daily_min_max", "location_id = #{location_id} AND day = '#{to_day_stamp(ts)}'")
    update_min_max(ts, "measurements_monthly_min_max", "location_id = #{location_id} AND year_month = '#{to_year_month(ts)}'")

    if stats.nil? || stats["first_read_at"].nil? || stats["first_read_at"] > ts
      cql = "UPDATE measurements_stats SET first_read_at='#{ts_to_cassandra(ts)}' WHERE location_id = #{location_id}"
      execute_cql(cql)
    end

    cql = "UPDATE measurements_stats SET current=#{measurement}, last_read_at='#{ts_to_cassandra(ts)}', voltage=#{voltage}, signal_strength=#{signal_strength} WHERE location_id = #{location_id}"
    execute_cql(cql)
  end

  def ts_to_cassandra(ts)
    ts.strftime('%Y-%m-%d %H:%M:%S')
  end

  def to_hour_stamp(ts)
    ts.strftime('%Y-%m-%d %H:00:00')
  end

  def to_day_stamp(ts)
    ts.strftime('%Y-%m-%d 00:00:00Z')
  end

  def to_year_month(timestamp)
    timestamp.strftime("%Y-%m")
  end

  private
  def self.year_months_from_dates(start_time, end_time)
    (start_time.to_i..(end_time + 1.day).to_i).step(1.day).map { |t| "'" + ts_to_year_month(Time.at(t)) + "'" }.uniq
  end

end
