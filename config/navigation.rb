# -*- encoding : utf-8 -*-
SimpleNavigation::Configuration.run do |navigation|  
  navigation.items do |primary|
    primary.item :measurements, 'Measurements', url_for(:root) do |measurements|
      measurements.item :overview, 'Overview', url_for(controller: :index, action: :overview)
      measurements.item :index, 'Graphs', url_for(controller: :index, action: :show)
      measurements.item :logs, 'Logs', url_for(:logs), if: proc { current_user }
    end
    primary.item :alarms, 'Alarms', url_for(:alarms), if: proc { current_user }
    primary.item :locations, 'Locations', url_for(:locations), if: proc { current_user }
    primary.item :clients, 'Clients', url_for(:clients), if: proc { current_user }
    primary.item :registered_users, 'Users', url_for(:registered_users), if: proc { current_user.try(:admin?) }
    primary.item :settings, 'Profile',url_for(:edit_user_registration), if: proc { current_user }
  end
end
