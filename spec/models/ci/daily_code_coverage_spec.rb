# frozen_string_literal: true

require 'spec_helper'

describe Ci::DailyCodeCoverage do
  describe '::create_or_update_for_build' do
    let!(:build) { create(:ci_build, created_at: '2020-02-06 00:01:10', name: 'rspec', coverage: 80) }

    context 'when there is no existing record with matching project_id, ref, name, date' do
      it 'creates a new record for the given build' do
        described_class.create_or_update_for_build(build)

        expect(described_class.last).to have_attributes(
          project_id: build.project.id,
          last_build_id: build.id,
          ref: build.ref,
          name: build.name,
          coverage: build.coverage,
          date: build.created_at.to_date
        )
      end
    end

    context 'when there is existing record with matching project_id, ref, name, date' do
      let!(:new_build) { create(:ci_build, project: build.project, created_at: build.created_at, ref: build.ref, name: build.name, coverage: 99) }
      let!(:existing) do
        create(
          :ci_daily_code_coverage,
          project_id: existing_build.project.id,
          last_build_id: existing_build.id,
          ref: existing_build.ref,
          name: existing_build.name,
          coverage: existing_build.coverage,
          date: existing_build.created_at.to_date
        )
      end

      context 'and build ID is newer than last_build_id' do
        let(:existing_build) { build }

        it 'updates the last_build_id and coverage' do
          described_class.create_or_update_for_build(new_build)

          existing.reload

          expect(existing).to have_attributes(
            last_build_id: new_build.id,
            coverage: new_build.coverage
          )
        end
      end

      context 'and build ID is not newer than last_build_id' do
        let(:existing_build) { new_build }

        it 'does not update the last_build_id and coverage' do
          described_class.create_or_update_for_build(build)

          existing.reload

          expect(existing).to have_attributes(
            last_build_id: new_build.id,
            coverage: new_build.coverage
          )
        end
      end
    end
  end
end
