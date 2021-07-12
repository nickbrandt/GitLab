# frozen_string_literal: true

namespace :gitlab do
  namespace :product_intelligence do
    desc 'GitLab | Product Intelligence | Update milestone metrics status to data_available'
    task :activate_metrics, [:milestone] do |t, args|
      puts "Changing status from implemented to data_available"
      milestone = args[:milestone]
      command = "egrep -l -R \"milestone\: (\\\"|\\\')#{milestone}(\\\"|\\\')\" ee/config/metrics config/metrics"
      milestone_metrics_files, status = Open3.capture2(command)

      exit(1) unless status.exitstatus.zero?

      milestone_metrics_files.split("\n").each do |file|
        Open3.capture2("sed -i '' -e 's/status\: implemented/status\: data_available/g' #{file}")
      end

      puts "Activate Metrics Task completed successfully"
    end
  end
end
