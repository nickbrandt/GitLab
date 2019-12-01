# frozen_string_literal: true

require 'spec_helper'

describe Issues::CreateService do
  let(:group)   { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user)    { create(:user) }
  let(:epic)    { create(:epic, group: group) }
  let(:service) { described_class.new(project, user, params) }

  before do
    stub_licensed_features(epics: true)
  end

  context 'quick actions' do
    before do
      project.add_maintainer(user)
    end

    context '/epic action' do
      let(:params) do
        {
          title: 'New issue',
          description: "/epic #{epic.to_reference(project)}"
        }
      end

      it 'adds an issue to the passed epic' do
        issue = service.execute

        expect(issue).to be_persisted
        expect(issue.epic).to eq(epic)
      end
    end
  end

  describe '#execute' do
    it_behaves_like 'new issuable with scoped labels' do
      let(:parent) { project }
    end

    it_behaves_like 'issue with epic_id parameter' do
      let(:execute) { service.execute }
    end
  end
end
