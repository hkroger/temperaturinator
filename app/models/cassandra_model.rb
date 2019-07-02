# -*- encoding : utf-8 -*-
require 'cassandra'
require 'active_model'

class CassandraModel
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  include ActiveModel::Conversion

  MAX_AGE_IN_SEC = 60
  UNQUOTED_TYPES = [Fixnum, TrueClass, FalseClass, Cassandra::Uuid, Cassandra::TimeUuid, Float, BigDecimal]
  cattr_accessor :client_created
  cattr_accessor :session
  attr_accessor :params
  attr_accessor :old_params

  def persisted?
    @persisted || false
  end

  def [](a)
    @params[a]
  end

  def []=(a,b)
    @params[a] = b
  end

  def initialize(hsh={}, persisted=false)
    @params = {}
    hsh.keys.each do |field|
      send((field.to_s+"=").to_sym, hsh[field])
    end
    if respond_to?(:created_at=) and created_at.nil?
      self.created_at=Time.now
    end
    if respond_to?(:updated_at=)
      self.updated_at=Time.now
    end
    @persisted = persisted
    @old_params = @params.dup if persisted
  end

  def create
    value_map = map_attributes
    cql = "INSERT INTO #{self.class.table_name}(#{value_map.keys.join(",")}) VALUES(#{value_map.values.join(",")})"
    result = execute_cql(cql)
    @persisted = true
  end

  def self.all
    find_by_cql("SELECT #{fields.join(",")} FROM #{table_name}")
  end

  def self.first
    find_by_cql("SELECT #{fields.join(",")} FROM #{table_name} LIMIT 1").first
  end

  def self.first_by_condition(cond)
    find_by_cql("SELECT #{fields.join(",")} FROM #{table_name} WHERE #{cond} LIMIT 1").first
  end

  def self.find_by_condition(cond)
    find_by_cql("SELECT #{fields.join(",")} FROM #{table_name} WHERE #{cond}")
  end

  def self.first_by_prepare(cond, *params)
    cql = "SELECT #{fields.join(",")} FROM #{table_name} WHERE #{cond} LIMIT 1"
    statement = session.prepare(cql)
    results = execute_cql(statement, *params)
    results.map { |row| new(row, true) }.first
  end

  def self.find_by_prepare(cond, *params)
    cql = "SELECT #{fields.join(",")} FROM #{table_name} WHERE #{cond}"
    statement = session.prepare(cql)
    results = execute_cql(statement, *params)
    results.map { |row| new(row, true) }
  end

  def self.delete_by_prepare(cond, *params)
    cql = "DELETE FROM #{table_name} WHERE #{cond}"
    statement = session.prepare(cql)
    results = execute_cql(statement, *params)
    @deleted = true
    results
  end

  def self.find_by_cql(cql)
    results = execute_cql(cql)
    results.map { |row| new(row, true) }
  end

  def self.execute_paged_cql(cql, page_size)
    Rails.logger.debug("CQL: #{cql.inspect}")
    session.execute(cql, page_size: page_size)
  end

  def execute_paged_cql(cql, page_size)
    self.class.execute_cql(cql, page_size)
  end

  def self.execute_cql(cql, *others)
    Rails.logger.debug("CQL: #{cql.inspect}")
    session.execute(cql, arguments: others)
  end

  def execute_cql(cql, *others)
    self.class.execute_cql(cql, *others)
  end

  def self.session
    @@session ||= create_session
  end

  def self.create_session
    @@client_created = Time.now

    cassandra_configs = YAML.load_file(File.join(Rails.root, "config", "cassandra.yml"))
    config = cassandra_configs[Rails.env.to_s]
    raise "No #{Rails.env} config in cassandra.yml" unless config
    raise "No hosts for #{Rails.env} config in cassandra.yml" unless config['hosts']
    raise "No keyspace for #{Rails.env} config in cassandra.yml" unless config['keyspace']
    
    interval = 2 # reconnect every 2 seconds
    policy   = Cassandra::Reconnection::Policies::Constant.new(interval)
    env_hosts = (ENV["DB_HOSTS"] || "").split(",")

    hosts = env_hosts.empty? ? config["hosts"] : env_hosts

    cluster = Cassandra.cluster(:logger => Rails.logger, :reconnection_policy => policy, :hosts => hosts, :consistency => :one)
    session = cluster.connect(config['keyspace'])
    session 
  end

  def self.ts_to_year_month(ts)
    ts.strftime("%Y-%m")
  end

  def self.year_month_to_ts(ym)
    Time.parse(ym+"-01")
  end

  def map_attributes
    value_map = {}
    self.class.fields.each do |f|
      f = f.to_s
      value = send(f.to_sym)
      value = value.to_s(:db) if value and value.is_a? Time
      value = value_to_cassandra(value)
      value_map[f] = value if value
    end
    value_map
  end

  def value_to_cassandra(value)
    if value.is_a? Symbol
      value = value.to_s
    end

    if value and value.is_a? String
      return "'#{value.gsub("'","''")}'"
    end

    if value and value.is_a? Set
      return "{" + value.to_a.map{|v| value_to_cassandra(v)}.join(",") + "}"
    end

    if value and value.is_a? Array
      return "[" + value.to_a.map{|v| value_to_cassandra(v)}.join(",") + "]"
    end

    return value.to_s if UNQUOTED_TYPES.include? value.class
    return "NULL" if value.nil?

    nil
  end

  def respond_to?(method_name, include_private = false)
    self.class.fields.include?(method_name.to_s) ||
      self.class.fields.include?(method_name.to_s.gsub(/=$/,"")) ||
      super
  end

  def method_missing(method_name, *args, &block)
    if self.class.fields.include? method_name.to_s
      return @params[method_name.to_s]
    end

    if self.class.fields.include? method_name.to_s.gsub(/=$/,"")
      return @params[method_name.to_s.gsub(/=$/,"")] = args.first
    end

    super
  end

  def save(opts={})
    default_opts = {:validate => true}
    opts = default_opts.merge(opts)
    return false if !valid? and opts[:validate] == true
    return false if @deleted
    if !persisted?
      create
    else
      update
    end
    @old_params = @params.dup
    true
  end

  def gen_uuid
    Cassandra::Uuid.new(SecureRandom.uuid)
  end

  def gen_timeuuid
    Cassandra::TimeUuid::Generator.new.now
  end
end
