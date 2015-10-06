# -*- encoding : utf-8 -*-
require 'pry'

class Sensor < CassandraModel
  extend Devise::Models

  def self.table_name; "sensors";end

  def self.find_by_id(id)
    first_by_condition("id = #{id.to_i}")
  end

  def self.fields
    %w(id location_id)
  end
end
