# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Board'] do
  it 'includes the ee specific fields' do
    expect(described_class).to have_graphql_field('weight')
  end
end
