# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Query'] do
  it do
    is_expected.to have_graphql_fields(:design_management).at_least
  end
end
