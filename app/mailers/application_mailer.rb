class ApplicationMailer < ActionMailer::Base
  default from: "nobody@measurinator.com"
  layout 'mailer'
end
