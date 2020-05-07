# frozen_string_literal: true

module Types
  class PackageTypeEnum < BaseEnum
    ::Packages::Package.package_types.keys.each do |package_type|
        value package_type.to_s.upcase, value: package_type.to_s
    end
  end
end
  