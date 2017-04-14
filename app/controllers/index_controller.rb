# -*- encoding : utf-8 -*-
class IndexController < ApplicationController
  def overview
    if params[:client].present?
      @client = Client.find_by_id(params[:client])
    else
      client_id = session[:client_id] || user_default_client_id
      @client = client_id ? Client.find_by_id(client_id) : Client.first
    end
    session[:client_id] = @client.id if @client

    @type = params[:type] || session[:type]
    @type = 'measurements' unless %w(measurements daily hourly monthly).include? @type
    session[:type] = @type

    # TODO: This is sub-optimal
    @locations = Location.all.select{ |l| l.client_id == @client.id }
    @locations.reject! { |l| l.do_not_show }
    @locations.sort_by! { |l| l.description }
  end

  def show
    @width = 560 * 2
    @location = params[:location] || session[:location] || 'All'
    if params[:client].present?
      @client = Client.find_by_id(params[:client])
    else
      client_id = session[:client_id] || user_default_client_id
      @client = client_id ? Client.find_by_id(client_id) : Client.first
    end
    session[:client_id] = @client.id if @client
    session[:location] = @location

    @type = params[:type] || session[:type]
    @type = 'measurements' unless %w(measurements daily hourly monthly).include? @type
    session[:type] = @type

    @locations = [Location.find_by_id(@location)].select{ |l| l.client_id == @client.id }.compact if @location != 'All'
    # TODO: This is sub-optimal
    @locations = Location.all.select{ |l| l.client_id == @client.id } if !@locations || @locations.length == 0
    @locations.reject! { |l| l.do_not_show }
    @measurement_days = [(params[:measurement_days].try(:to_i) || session[:measurement_days].try(:to_i) || 1),1].max
    limit_days
    session[:measurement_days] = @measurement_days 

    @datatime = @measurement_days.days.ago
  end

  private

  def user_default_client_id
    if user_signed_in?
      current_user.default_client_id
    end
  end

  def limit_days
    max_days = { :measurements => 7, :hourly => 365 }
    min_days = { :daily=> 30, :monthly=> 180}
    max_d = max_days[@type.to_sym]
    min_d = min_days[@type.to_sym]
    @measurement_days = [max_d, @measurement_days].min if max_d
    @measurement_days = [min_d, @measurement_days].max if min_d
  end
end
