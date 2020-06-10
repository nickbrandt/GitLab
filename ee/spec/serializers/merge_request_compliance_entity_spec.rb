# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestComplianceEntity do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, state: :merged) }

  let(:request) { double('request', current_user: user, project: project) }
  let(:entity) { described_class.new(merge_request, request: request) }

  describe '.as_json' do
    subject { entity.as_json }

    it 'includes merge request attributes for compliance' do
      expect(subject).to include(
        :id, :title, :merged_at, :milestone, :path, :issuable_reference, :approved_by_users
      )
    end

    describe 'with a approver' do
      let_it_be(:approver) { create(:user) }
      let!(:approval) { create :approval, merge_request: merge_request, user: approver }

      before do
        project.add_developer(approver)
      end

      it 'includes only set of approver details' do
        expect(subject[:approved_by_users].count).to eq(1)
      end

      it 'includes approver user details' do
        expect(subject[:approved_by_users][0][:id]).to eq(approver.id)
      end
    end

    describe 'with a head pipeline' do
      let!(:pipeline) { create(:ci_empty_pipeline, status: :success, project: project, head_pipeline_of: merge_request) }

      describe 'and the user cannot read the pipeline' do
        it 'does not include pipeline status attribute' do
          expect(subject).not_to have_key(:pipeline_status)
        end
      end

      describe 'and the user can read the pipeline' do
        before do
          project.add_developer(user)
        end

        it 'includes pipeline status attribute' do
          expect(subject).to have_key(:pipeline_status)
        end
      end
    end
  end
end
