class BaseAlarmLog < CassandraModel
  def location
    @location_cache ||= Location.find_by_id(location_id)
  end
end
