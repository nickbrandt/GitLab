# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['AccessLevelEnum'] do
  specify { expect(described_class.graphql_name).to eq('AccessLevelEnum') }
end
