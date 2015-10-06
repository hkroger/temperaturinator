# -*- encoding : utf-8 -*-
class Client < CassandraModel
  def self.table_name 
    "clients"
  end

  def self.find_by_id(id)
    raise "invalid id" unless id.is_a?(Cassandra::TimeUuid)||Uuid.is_uuid(id)
    first_by_condition("id = #{id}")
  end

  def self.fields
    %w(id disabled_at name signing_key user)
  end

  def destroy
    raise "invalid id" unless id.is_a?(Cassandra::TimeUuid)||Uuid.is_uuid(id)
    self.class.delete_by_prepare("id = ?", id)
  end

  def update
    value_map = map_attributes
    sets = value_map.keys.select{ |k| !%w(id).include? k.to_s}.map{ |k| k.to_s + "=" + value_map[k] }.join(",")
    cql = "UPDATE #{self.class.table_name} SET #{sets} WHERE id = #{id}"
    result = execute_cql(cql)
    @persisted = true
  end

  def generate_signing_key
    self.signing_key = gen_uuid if signing_key.blank?
  end

  def generate_id
    self.id = gen_timeuuid if id.blank?
  end
end
