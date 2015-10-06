# -*- encoding : utf-8 -*-
class Uuid
  REGEX = /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/

  def self.is_uuid(fragment)
    !!(fragment =~ REGEX)
  end
end
