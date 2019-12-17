class PasswordMailer < ApplicationMailer
  def reset_password_email(user, new_password)
    @user = user
    @new_password = new_password
    mail(to: @user.email, subject: 'Measurinator password reset')
  end
end
