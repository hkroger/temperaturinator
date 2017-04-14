# -*- encoding : utf-8 -*-
class LocationsController < AuthorizedController
  def index
    @locations = Location.all.select { |l| current_user.admin? || l.username == current_user.username }.sort_by{ |i| i.description }
    @clients = @locations.map{|l| l.client_id}.uniq.map do |client_id|
       Client.find_by_id(client_id)
    end.sort_by{ |c| c.name }
  end

  def new
    @location = Location.new
  end

  def edit
    @location = Location.find_by_id(params[:id])
  end
  
  def create
    if not params[:old_id].blank?
      a = Location.find_by_id(params[:old_id])
      a.username = params[:username]
    else
      a = Location.new
      begin
        a.id = Random.rand(100000000)
        existing_location = Location.find_by_id(a.id)
      end while !existing_location.nil?
      
      a.username = current_user.username
    end

    a.description = params[:name]
    a.client_id = Cassandra::Uuid.new(params[:client_id])
    a.do_not_show = params[:do_not_show].present?
    a.do_not_alarm = params[:do_not_alarm].present?
    a.sensors = Set.new(params[:sensor_list].gsub(" ","").split(",").map(&:to_i))

    a.sensors.each do |sensor|
      s = Sensor.find_by_id(sensor)
      if s and s.location_id != a.id
        redirect_to locations_path, :notice => "Cannot save. Sensor already used by some other location (#{s.location_id})." and return
      end
    end

    a.save

    redirect_to locations_path, :notice => params[:id] ? "Location has been updated." : "Location has been created."
  end

  def show
    @location = Location.find(params[:id])
  end

  def toggle
    raise "Wut?" unless %w(email pushover).include? params[:notification] 
    raise "Wut2?" unless %w(true false).include? params[:value] 
    value =  params['value'] == 'true'
    location = Cassandra::TimeUuid.new(params[:id])
    an = LocationNotification.find_by_location_and_user(location, current_user.username)
    if an.nil?
      an = LocationNotification.new(:location_id => location,
                                 params['notification'] => value,
                                 :username => current_user.username)
      an.save
    else
      an.send(params['notification'] + "=", value)
      an.save
    end

    redirect_to locations_path
  end

  def destroy
    @location = Location.find_by_id(params[:id])
    @location.sensors.each do |sensor|
      Sensor.delete_by_prepare("id = ?", sensor)
    end if @location.sensors

    @location.destroy
    redirect_to locations_path, :notice => "Location has been deleted successfully."
  end
end
