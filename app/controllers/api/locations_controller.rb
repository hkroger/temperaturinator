# -*- encoding : utf-8 -*-
require 'digest/sha1'

module Api
  class LocationsController < ApiController 
    class ChecksumDoesNotMatch < Exception;end
    class NotAuthorizedException < Exception;end

    def get
      client = verify_client(params)

      locations = Location.find_by_client_id(client.id).map(&:params).map{|p| p.slice("id", "description", "quantity")}
      render :json => locations
    rescue InvalidParameters => e
      render :text => e.message, :status => 400
    rescue ChecksumDoesNotMatch => e
      render :text => e.message, :status => 401
    rescue NotAuthorizedException => e
      render :text => e.message, :status => 403
    end
  end
end
