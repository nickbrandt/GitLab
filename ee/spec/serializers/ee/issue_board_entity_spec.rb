# frozen_string_literal: true

require 'spec_helper'

describe IssueBoardEntity do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(issue.reload, request: request).as_json }

  describe '#weight' do
    it 'has `weight` attribute' do
      expect(subject).to include(:weight)
    end

    context 'when project does not support issue weights' do
      before do
        stub_licensed_features(issue_weights: false)
      end

      it 'does not have `weight` attribute' do
        expect(subject).not_to include(:weight)
      end
    end
  end

  describe '#blocked' do
    it 'is not blocked by default' do
      expect(subject[:blocked]).to be_falsey
    end

    context 'when the issue is referenced by other issue' do
      let_it_be(:project2) { create(:project) }
      let_it_be(:related_issue) { create(:issue, project: project2) }

      context 'when the issue is blocking' do
        let_it_be(:issue_link) { create(:issue_link, source: related_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS) }

        context 'when the referencing issue is not visible to the user' do
          it 'is not blocked' do
            expect(subject[:blocked]).to be_falsey
          end
        end

        context 'when the referencing issue is visible to the user' do
          before do
            project2.add_developer(user)
          end

          it 'is blocked' do
            expect(subject[:blocked]).to be_truthy
          end
        end
      end

      context 'when the issue is not blocking' do
        let_it_be(:issue_link) { create(:issue_link, source: related_issue, target: issue, link_type: IssueLink::TYPE_RELATES_TO) }

        before do
          project2.add_developer(user)
        end

        it 'is not blocked' do
          expect(subject[:blocked]).to be_falsey
        end
      end
    end
  end
end
