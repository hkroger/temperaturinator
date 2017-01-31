# -*- encoding : utf-8 -*-
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.default_url_options[:host] = "localhost:3000"
