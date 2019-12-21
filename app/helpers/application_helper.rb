# -*- encoding : utf-8 -*-
module ApplicationHelper
  def time_ranges(type, days)
    case type
      when 'measurements'
        options_for_select((1..7).map{|i| [i.to_s + " days",i] }, days)
      when 'hourly'
        options_for_select((1..7).map{|i| [i.to_s + " days",i] }+
                           (1..4).map{|i| [i.to_s + " weeks", i*7]}+
                           (1..12).map{|i| [i.to_s + " months", i*30]},
                                        days
                          )
      when 'daily'
        options_for_select((1..24).map{|i| [i.to_s + " months", i*30]},
                                        days
                          )
      when 'monthly'
        options_for_select((6..24).map{|i| [i.to_s + " months", i*30]}, days)
    end
  end

  def ms_to_time(ms)
    sec = (ms.to_f / 1000).to_s
    Time.strptime(sec, '%s')
  end

  def format_time_and_date(time)
    return nil if time.nil?
    time.localtime.strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_time_only(time)
    return nil if time.nil?
    time.localtime.strftime("%H:%M:%S")
  end

  def diff_time_only(time_diff)
    return nil if time_diff.nil?
    Time.at(time_diff.to_i.abs).utc.strftime("%H:%M:%S")
  end

  def group_locations_for_select(selected)
    all_locs = Location.all.select{ |l| !l.do_not_show }
    client_ids = all_locs.map { |l| l.client_id }.uniq
    grouped = client_ids.map do |client_id|
      [Client.find_by_id(client_id).name,
          all_locs.select { |l| l.client_id == client_id }.map{ |l| [l.description.capitalize, l.id] }
      ]
    end

    grouped_options_for_select(grouped, selected)
  end
end
