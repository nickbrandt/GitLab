# frozen_string_literal: true

RSpec.shared_examples 'issue with epic_id parameter' do
  before do
    stub_licensed_features(epics: true)
  end

  context 'when epic_id does not exist' do
    let(:params) { { title: 'issue1', epic_id: -1 } }

    it 'raises an exception' do
      expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when user can not add issues to the epic' do
    before do
      project.add_maintainer(user)
    end

    let(:params) { { title: 'issue1', epic_id: epic.id } }

    it 'raises an exception' do
      expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when user can add issues to the epic' do
    before do
      group.add_owner(user)
      project.add_maintainer(user)
    end

    let(:params) { { title: 'issue1', epic_id: epic.id } }

    it 'creates epic issue link' do
      issue = execute

      expect(issue).to be_persisted
      expect(issue.epic).to eq(epic)
    end
  end
end
