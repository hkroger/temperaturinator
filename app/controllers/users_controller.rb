# -*- encoding : utf-8 -*-
class UsersController < AuthorizedController
  before_filter :admin_only

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def edit
    @user = User.find_by_username(params[:id])
  end
  
  def update
    create
  end

  def create
    if params[:id]
      a = User.find_by_username(params[:id])
    else
      a = User.new
      a.owner = current_user.username
    end

    a.is_admin = !!params[:is_admin]
    a.name = params[:name]
    a.deleted_at = Time.parse(params[:deleted_at]) rescue nil
    a.pushover = params[:pushover]
    a.email = params[:email]
    a.problem_report_method = params[:problem_report_method]
    a.reading_error_interval = params[:reading_error_interval].to_i
    a.default_client_id = Cassandra::Uuid.new(params[:default_client_id])
    a.save

    redirect_to registered_users_path, :notice => params[:id] ? "User has been updated." : "User has been created."
  end

  def show
    @user = User.find(params[:id])
  end

  def destroy
    @user = User.find_by_username(params[:id])
    @user.destroy
    redirect_to registered_users_path, :notice => "User has been deleted successfully."
  end
end
