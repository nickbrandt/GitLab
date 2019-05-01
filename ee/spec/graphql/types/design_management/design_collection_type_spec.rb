# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['DesignCollection'] do
  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it { expect(described_class).to have_graphql_fields(:project, :issue, :designs, :versions) }
end
