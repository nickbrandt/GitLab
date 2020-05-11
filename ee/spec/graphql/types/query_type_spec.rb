# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Query'] do
  specify do
    expect(described_class).to have_graphql_fields(
      :design_management,
      :geo_node,
      :vulnerabilities,
      :instance_security_dashboard,
      :vulnerabilities_count_by_day_and_severity
    ).at_least
  end
end
