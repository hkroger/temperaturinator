class AlarmLogsByAlarm < BaseAlarmLog
  def self.fields
    %w(client_id id location_id alarm_id message measurement)
  end

  def self.table_name
    "alarm_logs_by_alarm"
  end

  def self.find_by_alarm_id(id)
    id = Cassandra::Uuid.new(id)
    find_by_condition("alarm_id = #{id}")
  end
end
