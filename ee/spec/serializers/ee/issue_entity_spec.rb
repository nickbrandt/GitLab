# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:resource) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:blocking_issue) { create(:issue, project: project) }
  let_it_be(:blocked_issue) { create(:issue, project: project) }

  let(:request) { double('request', current_user: user) }

  before_all do
    project.add_developer(user)
    create(:issue_link, source: blocking_issue, target: blocked_issue, link_type: IssueLink::TYPE_BLOCKS)
  end

  subject(:rendered) { described_class.new(resource, request: request).as_json }

  context 'when with_blocking_issues option is not present' do
    it 'exposes blocking issues' do
      expect(subject).not_to include(:blocked)
      expect(subject).not_to include(:blocked_by_issues)
    end
  end

  context 'when with_blocking_issues option is present' do
    subject { described_class.new(resource, request: request, with_blocking_issues: true).as_json }

    it 'exposes blocking issues' do
      expect(subject).to include(:blocked)
      expect(subject).to include(:blocked_by_issues)
    end

    it 'exposes only iid and web_url' do
      response = described_class.new(blocked_issue, request: request, with_blocking_issues: true).as_json

      expect(response[:blocked_by_issues].first.keys).to match_array([:iid, :web_url])
    end
  end

  context 'when issue belongs to an iteration' do
    let_it_be(:iteration) { create(:iteration, group: project.group) }

    before do
      resource.update!(iteration: iteration)
    end

    context 'when iterations feature is available' do
      before do
        stub_licensed_features(iterations: true)
      end

      it 'exposes iteration' do
        expect(rendered[:iteration]).to include('id' => iteration.id)
      end
    end

    context 'when iterations feature is not available' do
      before do
        stub_licensed_features(iterations: false)
      end

      it 'does not expose iteration' do
        expect(rendered[:iteration]).to be_nil
      end
    end
  end
end
