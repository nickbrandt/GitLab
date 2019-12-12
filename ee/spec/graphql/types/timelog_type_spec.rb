# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Timelog'] do
  let(:fields) { %i[date time_spent user issue] }

  it { expect(described_class.graphql_name).to eq('Timelog') }
  it { expect(described_class).to have_graphql_fields(fields) }
  it { expect(described_class).to require_graphql_authorizations(:read_group_timelogs) }

  describe 'user field' do
    subject { described_class.fields['user'] }

    it 'returns user' do
      is_expected.to have_non_null_graphql_type(Types::UserType)
    end
  end

  describe 'issue field' do
    subject { described_class.fields['issue'] }

    it 'returns issue' do
      is_expected.to have_graphql_type(Types::IssueType)
    end
  end
end
