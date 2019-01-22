require 'spec_helper'

describe Gitlab::Geo::Fdw, :geo do
  include ::EE::GeoHelpers

  describe 'enabled?' do
    it 'returns false when PostgreSQL FDW is not enabled' do
      expect(described_class).to receive(:count_tables).and_return(0)
      allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => true)

      expect(described_class.enabled?).to be_falsey
    end

    context 'with fdw capable' do
      before do
        allow(described_class).to receive(:fdw_capable?).and_return(true)
      end

      it 'returns true by default' do
        allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => nil)

        expect(described_class.enabled?).to be_truthy
      end

      it 'returns false if disabled in `config/database_geo.yml`' do
        allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => false)

        expect(described_class.enabled?).to be_falsey
      end

      it 'returns true if configured in `config/database_geo.yml`' do
        allow(Rails.configuration).to receive(:geo_database).and_return('fdw' => true)

        expect(described_class.enabled?).to be_truthy
      end
    end
  end

  describe '.gitlab_tables' do
    it 'excludes pg_ tables' do
      ActiveRecord::Base.connection.create_table(:pg_gitlab_test)

      expect(described_class.gitlab_tables).not_to include('pg_gitlab_test')

      ActiveRecord::Base.connection.drop_table(:pg_gitlab_test)
    end
  end

  describe 'fdw_up_to_date?' do
    context 'with mocked FDW environment' do
      it 'returns true when FDW is enabled and foreign schema has same tables as secondary database' do
        expect(described_class).to receive(:has_foreign_schema?).and_return(true)
        expect(described_class).to receive(:foreign_schema_tables_match?).and_return(true)

        expect(described_class.fdw_up_to_date?).to be_truthy
      end

      it 'returns false when FDW is enabled but tables in schema doesnt match' do
        expect(described_class).to receive(:has_foreign_schema?).and_return(true)
        expect(described_class).to receive(:foreign_schema_tables_match?).and_return(false)

        expect(described_class.fdw_up_to_date?).to be_falsey
      end

      it 'returns false when FDW is disabled' do
        expect(described_class).to receive(:has_foreign_schema?).and_return(false)

        expect(described_class.fdw_up_to_date?).to be_falsey
      end
    end

    context 'with functional FDW environment' do
      it 'returns true' do
        expect(described_class.fdw_up_to_date?).to be_truthy
      end
    end
  end

  describe 'count_tables' do
    context 'with functional FDW environment' do
      it 'returns same amount as defined in schema migration' do
        # When testing it locally, you may need to refresh FDW with:
        #
        # rake geo:db:test:refresh_foreign_tables
        expect(described_class.count_tables).to eq(ActiveRecord::Schema.tables.count)
      end
    end
  end
end
