# -*- coding: utf-8 -*-=
class Sufia::StatsAdmin
  def self.matches?(request)
    current_user = request.env['warden'].user
    return false if current_user.blank?
    current_user.groups.include? 'umg/up.dlt.scholarsphere-admin-viewers'
  end
end
