# frozen_string_literal: true

require Rails.root.join("spec/support/helpers/stub_requests.rb")

Dir[Rails.root.join("ee/spec/support/helpers/*.rb")].each { |f| require f }
Dir[Rails.root.join("ee/spec/support/shared_contexts/*.rb")].each { |f| require f }
Dir[Rails.root.join("ee/spec/support/shared_examples/*.rb")].each { |f| require f }
Dir[Rails.root.join("ee/spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.include EE::LicenseHelpers

  config.define_derived_metadata(file_path: %r{ee/spec/}) do |metadata|
    location = metadata[:location]

    metadata[:geo] = metadata.fetch(:geo, true) if location =~ %r{[/_]geo[/_]}
  end

  config.before(:all) do
    License.destroy_all # rubocop: disable Cop/DestroyAll
    TestLicense.init
  end

  config.around(:each, :geo_tracking_db) do |example|
    example.run if Gitlab::Geo.geo_database_configured?
  end

  config.around(:each, :geo_fdw) do |example|
    if Gitlab::Geo::Fdw.enabled? && Gitlab::Geo.geo_database_configured?
      # Disable transactions because a foreign table can't see changes
      # inside a transaction of a different connection.
      self.class.use_transactional_tests = false

      example.run

      delete_from_all_tables!(except: deletion_except_tables)
    end
  end
end
