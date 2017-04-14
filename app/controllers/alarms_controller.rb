# -*- encoding : utf-8 -*-

class AlarmsController < AuthorizedController

  def index
    @alarms = Alarm.all
    @clients = @alarms.map{|l| l.location.client_id}.uniq.map do |client_id|
       Client.find_by_id(client_id)
    end.sort_by{ |c| c.name }
  end

  def new
    @alarm = Alarm.new
  end

  def edit
    @alarm = Alarm.find_by_location_id_and_id(params[:location_id], params[:id])
    unless @alarm
      redirect_to alarms_path, :notice => "Alarm does not exist"
    end
  end

  def logs
    if params[:location_id]
      @logs = AlarmLogsByLocation.find_by_location_id(params[:location_id])
    elsif params[:client]
      @logs = AlarmLogsByClient.find_by_client_id(params[:client])
    elsif params[:id]
      @logs = AlarmLogsByAlarm.find_by_alarm_id(params[:id])
    else
      return redirect_to alarms_path, :notice => "Invalid log search parameters"
    end

    @clients = @logs.map{|l| l.client_id}.uniq.map do |client_id|
       Client.find_by_id(client_id)
    end
    @client_names = {}
    @clients.each do |c|
      @client_names[c.id] = c.name
    end


  end
  
  def create
    if params[:id].present?
      a = Alarm.find_by_location_id_and_id(params[:location], params[:id])
    else
      a = Alarm.new
      a.owner = current_user.username
    end

    a.location_id = params[:location].to_i
    a.temperature = params[:threshold].to_f
    a.hysteresis = params[:hysteresis].to_f.abs
    a.alarm_when_warmer = params[:alarm_when_warmer].to_i == 1
    a.two_way_alarm = params[:two_way_alarm].present?
    a.save

    redirect_to alarms_path, :notice => params[:id] ? "Alarm has been updated." : "Alarm has been created."
  end

  def show
    @alarm = Alarm.find_by_location_id_and_id(params[:location], params[:id])
  end

  def toggle
    raise "Wut?" unless %w(email pushover).include? params[:notification] 
    raise "Wut2?" unless %w(true false).include? params[:value] 
    value =  params['value'] == 'true'
    alarm = Cassandra::TimeUuid.new(params[:id])
    an = AlarmNotification.find_by_alarm_and_user(alarm, current_user.username)
    if an.nil?
      an = AlarmNotification.new(:alarm_id => alarm,
                                 params['notification'] => value,
                                 :username => current_user.username)
      an.save
    else
      an.send(params['notification'] + "=", value)
      an.save
    end

    redirect_to alarms_path
  end

  def destroy
    @alarm = Alarm.find_by_location_id_and_id(params[:location_id], params[:id])
    @alarm.destroy
    redirect_to alarms_path, :notice => "Alarm has been deleted successfully."
  end
end
