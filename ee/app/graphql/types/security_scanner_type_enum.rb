# frozen_string_literal: true

module Types
  class SecurityScannerTypeEnum < BaseEnum
    graphql_name 'SecurityScannerType'
    description 'The type of the security scanner.'

    ::EE::ProjectSecurityScannersInformation::SECURITY_SCANNERS_NAME_MAP.values.each do |scanner|
      value scanner
    end
  end
end
