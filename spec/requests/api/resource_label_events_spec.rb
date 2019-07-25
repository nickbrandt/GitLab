# frozen_string_literal: true

require 'spec_helper'

describe API::ResourceLabelEvents do
  set(:user) { create(:user) }
  set(:project) { create(:project, :public, :repository, namespace: user.namespace) }
  set(:private_user) { create(:user) }

  before do
    project.add_developer(user)
  end

  context 'when eventable is an Issue' do
    let(:issue) { create(:issue, project: project, author: user) }

    it_behaves_like 'resource_label_events API', 'projects', 'issues', 'iid' do
      let(:parent) { project }
      let(:eventable) { issue }
      let!(:event) { create(:resource_label_event, issue: issue) }
    end
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

  context 'when eventable is a Merge Request' do
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

    it_behaves_like 'resource_label_events API', 'projects', 'merge_requests', 'iid' do
      let(:parent) { project }
      let(:eventable) { merge_request }
      let!(:event) { create(:resource_label_event, merge_request: merge_request) }
    end
  end
end
