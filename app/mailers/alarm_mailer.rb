# -*- encoding : utf-8 -*-
class AlarmMailer < ActionMailer::Base
  default from: "nobody@measurinator.com"

  def alarm(email, text)
    mail(:to => email, :subject => text) do |format|
      format.html { render :text => text }
      format.text { render :text => text }
    end
  end
end
