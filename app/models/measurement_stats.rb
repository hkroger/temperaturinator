# -*- encoding : utf-8 -*-
class MeasurementStats < CassandraModel
  def self.fields
    %w(location_id alarmed_at current first_read_at last_read_at max max_at min min_at voltage signal_strength)
  end

  def self.table_name
    "measurements_stats"
  end

  def self.get(id)
    first_by_condition("location_id = #{id}")
  end

  def destroy
    self.class.delete_by_prepare("location_id = ?", location_id)
  end

  def update
    value_map = map_attributes
    sets = value_map.keys.select{ |k| k != 'location_id'}.map{ |k| k + "=" + value_map[k] }.join(",")
    cql = "UPDATE #{self.class.table_name} SET #{sets} WHERE location_id= #{location_id.to_i}"
    result = execute_cql(cql)
    @persisted = true
  end
end
