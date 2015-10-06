# -*- encoding : utf-8 -*-
require 'pry'

class ProcessStatus < CassandraModel
  extend Devise::Models
  
  def self.table_name; "process_statuses";end

  def self.fields
    %w(process_name last_updated_at)
  end

  def is_ok?
    last_updated_at > 15.minutes.ago && last_updated_at < 15.minutes.from_now
  end
end
