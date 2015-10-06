# -*- encoding : utf-8 -*-
class AuthorizedController < ApplicationController
  before_filter :authenticate_user!
  def admin_only
    if signed_in?
      raise 'Only admins allowed!' unless current_user.admin?
    else
      # or you can use the authenticate_user! devise provides to only allow signed_in users
      raise 'Please sign in!'
    end
  end
end
