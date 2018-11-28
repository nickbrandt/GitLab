require 'spec_helper'

describe Issues::CreateService do
  let(:project) { create(:project) }

  let(:opts) do
    {
      title: 'Awesome issue',
      description: 'please fix',
      weight: 9
    }
  end

  context 'when current user cannot admin issues in the project' do
    let(:guest) { create(:user) }

    before do
      project.add_guest(guest)
    end

    it 'filters out params that cannot be set without the :admin_issue permission' do
      issue = described_class.new(project, guest, opts).execute

      expect(issue).to be_persisted
      expect(issue.weight).to be_nil
    end
  end

  context 'when current user can admin issues in the project' do
    let(:reporter) { create(:user) }

    before do
      project.add_reporter(reporter)
    end

    it 'sets permitted params correctly' do
      issue = described_class.new(project, reporter, opts).execute

      expect(issue).to be_persisted
      expect(issue.weight).to eq(9)
    end
  end
end
