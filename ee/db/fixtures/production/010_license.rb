# frozen_string_literal: true

default_license_file = Settings.source.dirname + 'Gitlab.gitlab-license'
license_file = Pathname.new(ENV.fetch('GITLAB_LICENSE_FILE', default_license_file))

# Do not fail if the license was not specified in configuration or a file
# placed at the expected locations.
if license_file.exist?
  if ::License.new(data: license_file.read).save
    puts "License Added:\n\nFilePath: #{license_file}".color(:green)
  else
    puts "License Invalid:\n\nFilePath: #{license_file}".color(:red)
    raise "License Invalid"
  end
elsif !ENV['GITLAB_LICENSE_FILE'].blank?
  puts "License File Missing:\n\nFilePath: #{license_file}".color(:red)
  raise "License File Missing"
end
