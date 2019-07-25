# frozen_string_literal: true

require 'spec_helper'

describe API::ResourceLabelEvents do
  set(:user) { create(:user) }
  set(:project) { create(:project, :public, namespace: user.namespace) }

  before do
    project.add_developer(user)
  end

  context 'when eventable is an Epic' do
    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'resource_label_events API', 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:eventable) { epic }
      let!(:event) { create(:resource_label_event, epic: epic) }
    end
  end
end
