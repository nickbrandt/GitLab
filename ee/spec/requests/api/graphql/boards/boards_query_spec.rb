# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get list of boards' do
  include GraphqlHelpers

  include_context 'group and project boards query context'

  before do
    stub_licensed_features(multiple_group_issue_boards: true)
  end

  describe 'for a group' do
    let(:board_parent) { create(:group, :private) }

    it_behaves_like 'group and project boards query'
  end
end
