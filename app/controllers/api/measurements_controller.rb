# -*- encoding : utf-8 -*-
require 'digest/sha1'

module Api
  class MeasurementsController < ApplicationController
    class InvalidParameters < Exception;end
    class ChecksumDoesNotMatch < Exception;end
    class NotAuthorizedException < Exception;end

    def get
      client = verify_client(params)
      location_id = params[:location_id].to_i
      location = Location.find_by_id(location_id)
      raise NotAuthorizedException.new("Invalid location") unless location
      raise NotAuthorizedException.new("Client is not the owner of location") unless location.client_id.to_s == client.id.to_s

      stats = MeasurementStats.get(location_id)

      render :json => stats.params
    rescue InvalidParameters => e
      render :text => e.message, :status => 400
    rescue ChecksumDoesNotMatch => e
      render :text => e.message, :status => 401
    rescue NotAuthorizedException => e
      render :text => e.message, :status => 403
    end

    def create
      verify_checksum(params)
      uuid_gen = Cassandra::TimeUuid::Generator.new

      if params[:version].nil? or params[:version].to_i < 2
        event_time = Time.now
      else
        event_time = Time.at(params[:timestamp].to_i)
      end
      
      year_month = to_year_month(event_time)
      measurement = params[:measurement].to_f
      signal_strength = params[:signal_strength].try(:to_f)
      voltage = params[:voltage].try(:to_f)
      sensor_id = (params[:location_id] || params[:sensor_id]).to_i
      sensor = Sensor.find_by_id(sensor_id)
      raise NotAuthorizedException.new("Sensor could not be found") unless sensor
      location_id = sensor.location_id
      location = Location.find_by_id(location_id)

      raise NotAuthorizedException.new("Invalid location") unless location
      raise NotAuthorizedException.new("Client is not the owner of location") unless location.client_id.to_s == params[:client_id].to_s
      raise NotAuthorizedException.new("Invalid sensor for location") unless location.sensors.include? sensor_id

      m = Measurement.new(location_id: location_id, measurement: measurement, id: uuid_gen.at(event_time), year_month: year_month, signal_strength: signal_strength, voltage: voltage)
      m.save
      m.update_all_stats(event_time)

      render :nothing => true
    rescue InvalidParameters => e
      render :text => e.message, :status => 400
    rescue ChecksumDoesNotMatch => e
      render :text => e.message, :status => 401
    rescue NotAuthorizedException => e
      render :text => e.message, :status => 403
    end

    private

    def verify_client(pars) 
      raise InvalidParameters.new("invalid or missing client_id") unless Uuid.is_uuid(params[:client_id])
      client = Client.find_by_id(params[:client_id])
      raise InvalidParameters.new("client not found") unless client
      client
    end

    def verify_checksum(hsh)
      client = verify_client(hsh)
      raise ChecksumDoesNotMatch.new("checksum does not match #{params[:checksum]} was given but #{generate_checksum(hsh, client.signing_key)} was expected.") unless generate_checksum(hsh, client.signing_key) == params[:checksum]
    end

    def generate_checksum(hsh, secret)
      if hsh[:version] and hsh[:version].to_i == 2
        string = "#{hsh[:version]}&#{hsh[:timestamp]}&#{hsh[:voltage]}&#{hsh[:signal_strength]}&#{hsh[:client_id]}&#{hsh[:location_id]||hsh[:sensor_id]}&#{hsh[:measurement]}&#{secret}"
      elsif hsh[:version] and hsh[:version].to_i == 1
        string = "#{hsh[:version]}&#{hsh[:voltage]}&#{hsh[:signal_strength]}&#{hsh[:client_id]}&#{hsh[:location_id]||hsh[:sensor_id]}&#{hsh[:measurement]}&#{secret}"
      else
        string = "#{hsh[:client_id]}&#{hsh[:location_id]||hsh[:sensor_id]}&#{hsh[:measurement]}&#{secret}"
      end

      Digest::SHA1.hexdigest(string)
    end

    def to_year_month(timestamp)
      timestamp.strftime("%Y-%m")
    end

  end
end
