# -*- encoding : utf-8 -*-
class UsersController < AuthorizedController
  before_filter :admin_only

  def index
    @users = User.all.select{ |u| u.active? || params[:all] }
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
      a.username = params[:username]
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

  def reset_password
    @user = User.find_by_username(params[:id])

    characters = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a

    new_password = (0..12).map{characters.sample}.join

    @user.password = new_password
    @user.password_confirmation = new_password
    @user.save

    PasswordMailer.reset_password_email(@user, new_password).deliver_now
    redirect_to registered_users_path, :notice => "User '#{@user.username}' password has been reset."
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
