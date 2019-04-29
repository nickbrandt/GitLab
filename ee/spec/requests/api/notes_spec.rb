# frozen_string_literal: true

require 'spec_helper'

describe API::Notes do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :public, namespace: user.namespace) }
  let(:private_user) { create(:user) }

  before do
    project.add_reporter(user)
  end

  context "when noteable is an Epic" do
    let(:group) { create(:group, :public) }
    let(:epic) { create(:epic, group: group, author: user) }
    let!(:epic_note) { create(:note, noteable: epic, project: project, author: user) }

    before do
      group.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like "noteable API", 'groups', 'epics', 'id' do
      let(:parent) { group }
      let(:noteable) { epic }
      let(:note) { epic_note }
    end
  end
end
