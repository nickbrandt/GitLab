# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Source'] do
  specify { expect(described_class.graphql_name).to eq('Source') }
end
