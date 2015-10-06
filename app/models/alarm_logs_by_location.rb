class AlarmLogsByLocation < CassandraModel
  def self.fields
    %w(client_id id location_id alarm_id message measurement)
  end

  def self.table_name
    "alarm_logs_by_location"
  end

  def self.find_by_location_id(id)
    id = id.to_i
    find_by_condition("location_id = #{id}")
  end
end
