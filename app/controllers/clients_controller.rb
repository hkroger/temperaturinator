# -*- encoding : utf-8 -*-
class ClientsController < AuthorizedController
  def index
    @clients = Client.all
  end

  def new
    @client = Client.new
  end

  def edit
    @client = Client.find_by_id(params[:id])
  end
  
  def create
    if params[:id] && !params[:id].blank?
      client = Client.find_by_id(params[:id])
    else
      client = Client.new
      client.user = current_user.username
    end

    client.name = params[:name]
    client.user = params[:user] unless params[:user].blank?
    client.generate_signing_key
    client.generate_id
    client.save

    redirect_to clients_path, :notice => !params[:id].blank? ? "Client has been updated." : "Client has been created."
  end

  def show
    @client = Client.find(params[:id])
  end

  def toggle
    raise "Wut?" unless %w(email pushover).include? params[:notification] 
    raise "Wut2?" unless %w(true false).include? params[:value] 
    value =  params['value'] == 'true'
    client = Cassandra::TimeUuid.new(params[:id])
    an = ClientNotification.find_by_client_and_user(client, current_user.username)
    if an.nil?
      an = ClientNotification.new(:client_id => client,
                                 params['notification'] => value,
                                 :username => current_user.username)
      an.save
    else
      an.send(params['notification'] + "=", value)
      an.save
    end

    redirect_to clients_path
  end

  def destroy
    @client = Client.find_by_id(params[:id])
    @client.destroy
    redirect_to clients_path, :notice => "Client has been deleted successfully."
  end
end
