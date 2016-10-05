# -*- encoding : utf-8 -*-

class ApiController < ApplicationController
  class InvalidParameters < Exception;end

  protected 

  def verify_client(pars) 
    raise InvalidParameters.new("invalid or missing client_id") unless Uuid.is_uuid(params[:client_id])
    client = Client.find_by_id(params[:client_id])
    raise InvalidParameters.new("client not found") unless client
    client
  end
end
