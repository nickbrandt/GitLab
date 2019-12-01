# frozen_string_literal: true

namespace :gitlab do
  namespace :license do
    desc 'GitLab | Gather license related information'
    task info: :gitlab_environment do
      license = Gitlab::UsageData.license_usage_data
      puts "Today's Date: #{Date.today}"
      puts "Current User Count: #{license[:active_user_count]}"
      puts "Max Historical Count: #{license[:historical_max_users]}"
      puts "Max Users in License: #{license[:license_user_count]}"
      puts "License valid from: #{license[:license_starts_at]} to #{license[:license_expires_at]}"
      puts "Email associated with license: #{license[:licensee]['Email']}"
    end
  end
end
