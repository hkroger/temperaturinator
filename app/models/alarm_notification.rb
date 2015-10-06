# -*- encoding : utf-8 -*-
class AlarmNotification < CassandraModel
  def self.fields
    %w(alarm_id pushover email created_at updated_at username)
  end

  def self.table_name
    "alarm_notifications_by_alarm"
  end

  def self.find_by_alarm_id(alarm_id)
    raise "alarm_id should be timeuuid" unless alarm_id.is_a? Cassandra::TimeUuid
    find_by_condition("alarm_id = #{alarm_id}")
  end

  def self.find_by_alarm_and_user(alarm_id, user)
    raise "alarm_id should be timeuuid" unless alarm_id.is_a? Cassandra::TimeUuid
    first_by_prepare("alarm_id = ? and username = ?", alarm_id, user)
  end

  def update
    value_map = map_attributes
    sets = value_map.keys.select{ |k| !%w(username alarm_id).include? k}.map{ |k| k + "=" + value_map[k] }.join(",")
    cql = "UPDATE #{self.class.table_name} SET #{sets} WHERE username = '#{username}' and alarm_id = #{alarm_id}"
    result = execute_cql(cql)
    @persisted = true
  end

  def destroy
    self.class.delete_by_prepare("alarm_id = ? and username = ?", alarm_id, username)
  end

  def send_message(text)
    user = User.find_by_username(username)
    if pushover and user and user.pushover
      Pushover.send_message(user.pushover, text)
    end

    if email and user and user.email
      begin
        AlarmMailer.alarm(user.email, text).deliver
      rescue Net::SMTPFatalError => e
        Rails.logger.error "alarm notification failed: "
        Rails.logger.error e.inspect
      end
    end
  end
end
