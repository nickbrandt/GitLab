# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Group'] do
  describe 'nested epic request' do
    it { expect(described_class).to have_graphql_field(:epicsEnabled) }
    it { expect(described_class).to have_graphql_field(:epics) }
    it { expect(described_class).to have_graphql_field(:epic) }
  end
end
