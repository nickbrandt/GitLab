# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Group'] do
  describe 'nested epic request' do
    it { expect(described_class).to have_graphql_field(:epicsEnabled) }
    it { expect(described_class).to have_graphql_field(:epics) }
    it { expect(described_class).to have_graphql_field(:epic) }
  end

  it { expect(described_class).to have_graphql_field(:groupTimelogsEnabled) }
  it { expect(described_class).to have_graphql_field(:timelogs, complexity: 5) }

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'finds timelogs between start date and end date' do
      is_expected.to have_graphql_arguments(:start_date, :end_date, :after, :before, :first, :last)
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
      is_expected.to have_non_null_graphql_type(Types::TimelogType.connection_type)
    end
  end
end
