# -*- encoding : utf-8 -*-
class Alarm < CassandraModel
  before_validation :update_timestamp

  def update_timestamp
    self.updated_at = Time.now
  end

  def alarm_notifications
    AlarmNotification.find_by_alarm_id(id).select{ |n| n.email or n.pushover }
  end

  def self.table_name
    "alarms"
  end

  def hysteresis
    @params['hysteresis'] || 0
  end

  def delay
    @params['delay'] || 0
  end

  def self.fields
    %w(location_id id alarm_when_warmer alarmed created_at temperature two_way_alarm updated_at owner hysteresis delay)
  end

  def self.find_by_location_id(location_id)
    return [] unless location_id
    location_id = location_id.to_i
    find_by_condition("location_id = #{location_id}")
  end

  def self.find_by_location_id_and_id(location_id, id)
    return [] unless location_id
    return [] unless id
    id = Cassandra::TimeUuid.new(id) if id.is_a? String
    location_id = location_id.to_i
    first_by_prepare("location_id = ? and id = ?", location_id, id)
  end

  def destroy
    AlarmNotification.find_by_alarm_id(id).each { |an| an.destroy }
    self.class.delete_by_prepare("location_id = ? and id = ?", location_id, id)
  end

  def self.logger
    Rails.logger
  end

  def map_attributes
    attrs = super
    if !attrs['id'].present? || attrs['id'] == 'NULL'
      attrs['id'] = 'now()'
    end
    attrs
  end

  def update
    value_map = map_attributes
    sets = value_map.keys.select{ |k| !%w(location_id id).include? k.to_s}.map{ |k| k.to_s + "=" + value_map[k] }.join(",")
    cql = "UPDATE #{self.class.table_name} SET #{sets} WHERE location_id = #{location_id} and id = #{id}"
    result = execute_cql(cql)
    @persisted = true
  end
  
  def self.watch
    while true
      users = {}
      measurement_stats = MeasurementStats.all
      measurement_stats.each do |measurement|
        check_reading_problem(measurement, users)
        alarms = find_by_location_id(measurement.location_id)
        alarms.each do |alarm|
          alarm.check measurement['current']
        end
      end

      ProcessStatus.new(:process_name => 'alarm', :last_updated_at => Time.now).save
      sleep 15
    end
  end

  def self.check_reading_problem(measurement, users)
    last_read_at = measurement.last_read_at
    alarmed_at = measurement.alarmed_at
    location = Location.find_by_id(measurement.location_id)

    # Let's skip if location cannot be found
    return unless location

    username = location.username
    users[username] ||= User.find_by_username(username)
    user = users[username]
    if alarmed_at 
      if alarmed_at < last_read_at
        unless location.do_not_alarm
          report(user, "Temperature reading of #{location.description} resumed.")
          measurement.alarmed_at = nil
          measurement.save
        end
      end
    else
      if last_read_at and Time.now - last_read_at > user.reading_error_interval
        unless location.do_not_alarm
          report(user, "Temperature reading problem of #{location.description}. Last measurement got #{last_read_at}. Time now #{Time.now}.")
          measurement.alarmed_at = Time.now
          measurement.save
        end
      end
    end
  end

  def self.report(user, txt)
    user.report_problem(txt)
  end

  def check(measured_temp)
    if !alarmed
      if measured_temp > temperature and alarm_when_warmer
        alarm_hot measured_temp
      elsif measured_temp < temperature and !alarm_when_warmer
        alarm_cold measured_temp
      end
    else
      if measured_temp <= temperature-hysteresis and alarm_when_warmer
        unalarm_hot measured_temp
      elsif measured_temp >= temperature+hysteresis and !alarm_when_warmer
        unalarm_cold measured_temp
      end
    end
  end

  def location
    @location_cache ||= Location.find_by_id(location_id)
  end

  def pushover?(user)
    AlarmNotification.find_by_alarm_and_user(id, user.username).try(:pushover) || false
  end

  def email?(user)
    AlarmNotification.find_by_alarm_and_user(id, user.username).try(:email) || false
  end

  private

  def alarm_hot(temp)
    alarm temp, true, true
  end

  def alarm_cold(temp)
    alarm temp, false, true
  end

  def unalarm_hot(temp)
    alarm temp, true, false
  end

  def unalarm_cold(temp)
    alarm temp, false, false
  end

  def alarm(temp, hotter, alarming)
    if (alarming or two_way_alarm)
      msg = "#{location.description.capitalize} is #{"%.2f" % temp} deg. which #{alarming ? "is" : "isn't anymore"} #{hotter ? "hotter" : "colder" } than the alarm limit #{temperature} deg"
      do_alarm msg, location, temp
    end

    self.alarmed = alarming
    save
  end

  def do_alarm(text, location, measurement)
    alarm_log = {
      :id => Cassandra::Uuid::Generator.new.now,
      :client_id => location.client_id,
      :alarm_id => id,
      :location_id => location.id,
      :measurement => measurement,
      :message => text.dup
    }

    AlarmLogsByAlarm.new(alarm_log).save
    AlarmLogsByClient.new(alarm_log).save
    AlarmLogsByLocation.new(alarm_log).save
    alarm_notifications.each { |notification| notification.send_message(text) }
  end
end
