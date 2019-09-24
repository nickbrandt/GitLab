# frozen_string_literal: true

require 'spec_helper'

describe Evidenceable do
  describe '#ensure_evidence' do
    set(:project) { create(:project) }
    let(:release) { create(:release, project: project) }
    let(:milestone) { create(:milestone, project: project) }
    let(:issue) { create(:issue, project: project) }

    describe 'release' do
      context 'when an evidence object is linked to a release' do
        let(:model) { release }

        context 'when the updated field is part of the evidence JSON summary' do
          let(:updated_field) { :description }
          let(:updated_value) { 'updated description' }
          let(:updated_json_field) { Evidence.last.summary['description'] }

          it_behaves_like 'updated exposed field'
        end

        context 'when the updated field is not part of the evidence JSON summary' do
          let(:updated_field) { :released_at }
          let(:updated_value) { Time.now }

          it_behaves_like 'updated non-exposed field'
        end
      end
    end

    describe 'milestone' do
      let(:model) { milestone }

      context 'when a milestone is linked to a release object' do
        before do
          release.milestones << milestone
        end
        context 'when the updated field is part of the evidence JSON summary' do
          let(:updated_field) { :description }
          let(:updated_value) { 'updated description' }
          let(:updated_json_field) { Evidence.last.summary['milestones'][0]['description'] }

          it_behaves_like 'updated exposed field'
        end

        context 'when the updated field is not part of the evidence JSON summary' do
          let(:updated_field) { :start_date }
          let(:updated_value) { Time.now }

          it_behaves_like 'updated non-exposed field'
        end
      end

      context 'when a milestone is not linked to any release object' do
        let(:updated_field) { :description }
        let(:updated_value) { 'updated description' }

        it_behaves_like 'updated field on non-linked entity'
      end
    end

    describe 'issue' do
      let(:model) { issue }

      context 'when an issue is part of a milestone that is linked to a release' do
        before do
          milestone.issues << issue
          release.milestones << milestone
        end
        context 'when the updated field is part of the evidence JSON summary' do
          let(:updated_field) { :state }
          let(:updated_value) { 'closed' }
          let(:updated_json_field) { Evidence.last.summary['milestones'][0]['issues'][0]['state'] }

          it_behaves_like 'updated exposed field'
        end

        context 'when the updated field is not part of the evidence JSON summary' do
          let(:updated_field) { :weight }
          let(:updated_value) { 10 }

          it_behaves_like 'updated non-exposed field'
        end
      end

      context 'when an issue is part of a milestone that is not linked to a release' do
        let(:updated_field) { :description }
        let(:updated_value) { 'updated description' }

        before do
          milestone.issues << issue
        end

        it_behaves_like 'updated field on non-linked entity'
      end

      context 'when an issue is not part of any milestone' do
        let(:updated_field) { :description }
        let(:updated_value) { 'updated description' }

        it_behaves_like 'updated field on non-linked entity'
      end
    end
  end
end
