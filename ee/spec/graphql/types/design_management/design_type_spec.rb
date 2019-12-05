# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Design'] do
  it_behaves_like 'a GraphQL type with design fields' do
    let(:extra_design_fields) { %i[notes discussions versions] }
  end
end
