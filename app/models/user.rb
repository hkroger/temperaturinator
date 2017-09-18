# -*- encoding : utf-8 -*-
require 'pry'

class User < CassandraModel
  define_model_callbacks :update
  EMAIL='email'
  PUSHOVER='pushover'
  extend Devise::Models
  
  devise :database_authenticatable, :registerable,
         :rememberable, :trackable
  validates_presence_of :username
  validate :unique_username

  def unique_username
    errors.add(:username, "is not unique") if username and !username.empty? and !self.class.find_by_username(username).nil? and !persisted?
  end

  def report_problem(msg)
    if problem_report_method == EMAIL
      begin
        AlarmMailer.alarm(email, msg).deliver
      rescue Net::SMTPFatalError => e
        Rails.logger.error "report problem failed: "
        Rails.logger.error e.inspect
      end

    else
      Pushover.send_message(pushover, msg)
    end
  end

  def problem_report_method
    @params['problem_report_method'] || PUSHOVER
  end

  def reading_error_interval=(a)
    @params['reading_error_interval'] = a.to_i
  end

  def reading_error_interval 
    int = @params['reading_error_interval']
    (int if int and int>0) || 20.minutes
  end
  
  def self.table_name; "users";end

  def self.fields
    %w(username email encrypted_password reset_password_token 
       reset_password_sent_at remember_created_at sign_in_count 
       current_sign_in_at last_sign_in_at current_sign_in_ip 
       last_sign_in_ip created_at updated_at pushover
       deleted_at is_admin name problem_report_method 
       reading_error_interval default_client_id)
  end

  def self.find_by_username(username)
    first_by_prepare("username = ?", username)
  end

  def self.new_with_session(params, session)
    new(params, false)
  end

  def active?
    !deleted_at
  end

  def admin?
    is_admin
  end

  def [](field)
    send(field.to_sym)
  end

  def []=(field, value)
    send((field.to_s + "=").to_sym, value)
  end

  def to_key
    [username]
  end

  def self.to_adapter
    self
  end

  def self.get!(param)
    get(param)
  end

  def self.get(param)
    find_by_username(param.first)
  end

  def changed?
    true
  end

  def inactive_message
    !!deleted_at ? :deleted : super
  end

  def destroy
    self.deleted_at = Time.now
    save
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def update_attributes(attributes)
    assign_attributes(attributes)
    save
  end

  def assign_attributes(attributes)
    attributes.each do |k,v|
      self[k]=v
    end
  end

  # Special treatment
  def create
    fix_client_id
    value_map = map_attributes
    cql = "INSERT INTO #{self.class.table_name}(#{value_map.keys.join(",")}) VALUES(#{value_map.values.join(",")}) IF NOT EXISTS"
    result = execute_cql(cql)
    @persisted = true
  end

  def update
    fix_client_id
    value_map = map_attributes
    sets = value_map.keys.select{ |k| k != 'username'}.map{ |k| k + "=" + value_map[k] }.join(",")
    cql = "UPDATE #{self.class.table_name} SET #{sets} WHERE username = '#{username}'"
    result = execute_cql(cql)
    @persisted = true
  end

  def fix_client_id
    self[:default_client_id] = Cassandra::TimeUuid.new(default_client_id) if default_client_id.is_a? String
  end

  # <DEVISE>
  def self.find_for_authentication(opts)
    find_by_username(opts[:username])
  end

  def self.serialize_into_session(record)
    [record.username, record.authenticatable_salt]
  end

  def self.serialize_from_session(key, salt)
    record = find_by_username(key)
    record if record && record.authenticatable_salt == salt
  end
  # </DEVISE>
end
