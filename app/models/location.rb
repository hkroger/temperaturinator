# -*- encoding : utf-8 -*-
class Location < CassandraModel
  def self.fields
    %w(id description username client_id do_not_alarm do_not_show do_not_show_publically sensors)
  end

  def self.table_name
    "locations"
  end

  def self.find_ids_by_client_id(client_id)
    statement = session.prepare("SELECT id FROM locations_by_client WHERE client_id = ?")
    execute_cql(statement, client_id).map{|o| o["id"]}
  end

  def self.find_by_client_id(client_id)
    statement = session.prepare("SELECT id FROM locations_by_client WHERE client_id = ?")
    ids = execute_cql(statement, client_id).map{|o| o["id"]}
    find_by_prepare("id IN ?", ids)
  end

  def self.find_by_id(id)
    return nil if id.nil?
    first_by_condition("id = #{id.to_i}")
  end

  def description_with_client
    "#{description} (#{client.try(:name).try(:capitalize)})"
  end

  def client
    @client_cache ||= Client.cached_find_by_id(client_id)
  end

  def last_measurement
    MeasurementStats.get(id)
  end

  def sensor_list
    sensors.to_a.join(", ")
  end

  def update
    puts map_attributes.inspect
    value_map = map_attributes
    sets = value_map.keys.select{ |k| !%w(id).include? k.to_s}.map{ |k| k.to_s + "=" + value_map[k] }.join(",")
    cql = "UPDATE #{self.class.table_name} SET #{sets} WHERE id = #{id}"
    result = execute_cql(cql)
    @persisted = true
  end

  def save
    if @old_params and @old_params['sensors']
      to_be_deleted = @old_params['sensors'].to_a - sensors.to_a
      to_be_deleted.each do |sensor|
        Sensor.delete_by_prepare("id = ?", sensor)
      end
    end

    sensors.each do |sensor|
      Sensor.new(:id => sensor, :location_id => id).save
    end

    super
  end

  def destroy
    raise "invalid id" unless id.is_a? Integer
    Alarm.find_by_location_id(id).each { |loc| loc.destroy }
    ms = MeasurementStats.get(id)
    ms.destroy if ms
    self.class.delete_by_prepare("id = ?", id)
  end

  def datapoints(start, endtime=Time.now)
    measurements = Measurement.get_range(id, start, endtime)

    result = []
    measurements.each do |m|
      result << [m['timestamp'].to_i*1000, m['measurement'].round(2)]
    end
    result
  end

  def hourly_averages(start)
    get_averages(start, MeasurementHourly)
  end

  def monthly_averages(start)
    get_averages(start, MeasurementMonthly)
  end

  def monthly_min_max(start)
    get_min_max(start, MeasurementMonthly)
  end

  def daily_averages(start)
    get_averages(start, MeasurementDaily)
  end

  def daily_min_max(start)
    get_min_max(start, MeasurementDaily)
  end

  private

  def get_min_max(start, klass)
    klass.get_min_max(id, start, Time.now)
  end

  def get_averages(start, klass)
    measurements = klass.get_range(id, start, Time.now)

    result = []
    measurements.each do |m|
      ts = m['timestamp']
      if ts.is_a? String
        ts = Time.parse(ts+"-01")
      end
      ts = ts.localtime

      result << [ts.to_i*1000, (m['temperature_sum_in_cents'] / m['temperature_count'] / 100.0).round(2)]
    end
    result
  end
end
