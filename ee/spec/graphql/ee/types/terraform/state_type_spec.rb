# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformState'] do
  describe 'fields' do
    let(:fields) { %i[id name locked_by_user locked_at latest_version versions created_at updated_at] }

    it { expect(described_class).to have_graphql_fields(fields) }
    it { expect(described_class.fields['versions'].type).to be_non_null }
  end
end
