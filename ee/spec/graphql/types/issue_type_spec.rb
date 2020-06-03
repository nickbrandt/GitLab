# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to have_graphql_field(:epic) }

  it { expect(described_class).to have_graphql_field(:iteration) }

  it { expect(described_class).to have_graphql_field(:weight) }

  it { expect(described_class).to have_graphql_field(:health_status) }
end
