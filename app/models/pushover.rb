# -*- encoding : utf-8 -*-
require "net/http"

class Pushover
  def self.appkey=(appkey)
    @@appkey = appkey
  end

  def self.send_message(userkey, message)
    url = URI.parse("https://api.pushover.net/1/messages.json")
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data({
      :token => @@appkey,
      :user => userkey,
      :message => message,
    })
    res = Net::HTTP.new(url.host, url.port)
    res.use_ssl = true
    res.verify_mode = OpenSSL::SSL::VERIFY_PEER
    res.start {|http| http.request(req) }
  end

end
