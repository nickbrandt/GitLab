# frozen_string_literal: true

require 'spec_helper'

describe Evidence do
  let_it_be(:project) { create(:project) }
  let(:release) { create(:release, project: project) }
  let(:schema_file) { 'evidences/evidence' }
  let(:summary_json) { described_class.last.summary.to_json }

  describe 'associations' do
    it { is_expected.to belong_to(:release) }
  end

  describe '#sha' do
    it 'returns nil if summary is nil' do
      expect(build(:evidence, summary: nil).sha).to be_nil
    end

    it 'returns the correct SHA256 checksum for a given summary json' do
      summary_sample = { id: 123, summary: 'description' }
      checksum = Gitlab::CryptoHelper.sha256(summary_sample.as_json)
      evidence = build(:evidence, summary: summary_sample)

      expect(evidence.sha).to eq(checksum)
    end
  end

  describe '#generate_summary' do
    before do
      described_class.create!(release: release)
    end

    context 'when a release name is not provided' do
      let(:release) { create(:release, project: project, name: nil) }

      it 'creates a valid JSON object' do
        expect(release.name).to be_nil
        expect(summary_json).to match_schema(schema_file)
      end
    end

    context 'when a release is associated to a milestone' do
      let(:milestone) { create(:milestone, project: project) }
      let(:release) { create(:release, project: project, milestones: [milestone]) }

      context 'when a milestone has no issue associated with it' do
        it 'creates a valid JSON object' do
          expect(milestone.issues).to be_empty
          expect(summary_json).to match_schema(schema_file)
        end
      end

      context 'when a milestone has no description' do
        let(:milestone) { create(:milestone, project: project, description: nil) }

        it 'creates a valid JSON object' do
          expect(milestone.description).to be_nil
          expect(summary_json).to match_schema(schema_file)
        end
      end

      context 'when a milestone has no due_date' do
        let(:milestone) { create(:milestone, project: project, due_date: nil) }

        it 'creates a valid JSON object' do
          expect(milestone.due_date).to be_nil
          expect(summary_json).to match_schema(schema_file)
        end
      end

      context 'when a milestone has an issue' do
        context 'when the issue has no description' do
          let(:issue) { create(:issue, project: project, description: nil, state: 'closed') }

          before do
            milestone.issues << issue
          end

          it 'creates a valid JSON object' do
            expect(milestone.issues.first.description).to be_nil
            expect(summary_json).to match_schema(schema_file)
          end
        end
      end
    end

    context 'when a release is not associated to any milestone' do
      it 'creates a valid JSON object' do
        expect(release.milestones).to be_empty
        expect(summary_json).to match_schema(schema_file)
      end
    end
  end
end
