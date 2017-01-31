class RegistrationsController < Devise::RegistrationsController
  private

  ALLOWED_PARAMS = %i(username password password_confirmation email default_client_id pushover problem_report_method reading_error_interval)
  ALLOWED_PARAMS_UPDATE = ALLOWED_PARAMS + %i(current_password) - %i(username)

  def sign_up_params
    params.require(:user).permit(*ALLOWED_PARAMS)
  end

  def account_update_params
    params.require(:user).permit(*ALLOWED_PARAMS_UPDATE)
  end
end
