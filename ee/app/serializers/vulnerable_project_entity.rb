# frozen_string_literal: true

class VulnerableProjectEntity < ProjectEntity
  ::Vulnerabilities::Occurrence::SEVERITY_LEVELS.each_key do |severity_level|
    expose "#{severity_level}_vulnerability_count"
  end
end
