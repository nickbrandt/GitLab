# frozen_string_literal: true

require 'spec_helper'

describe Ci::DailyCodeCoverageService, '#execute' do
  let!(:pipeline) { create(:ci_pipeline, created_at: '2020-02-06 00:01:10') }
  let!(:rspec_job) { create(:ci_build, pipeline: pipeline, name: 'rspec', coverage: 80) }
  let!(:karma_job) { create(:ci_build, pipeline: pipeline, name: 'karma', coverage: 90) }
  let!(:extra_job) { create(:ci_build, pipeline: pipeline, name: 'extra', coverage: nil) }

  it 'creates daily code coverage record for each job in the pipeline that has coverage value' do
    described_class.new.execute(pipeline)

    DailyCodeCoverage.find_by(name: 'rspec').tap do |coverage|
      expect(coverage).to have_attributes(
        project_id: pipeline.project.id,
        last_pipeline_id: pipeline.id,
        ref: pipeline.ref,
        name: rspec_job.name,
        coverage: rspec_job.coverage,
        date: pipeline.created_at.to_date
      )
    end

    DailyCodeCoverage.find_by(name: 'karma').tap do |coverage|
      expect(coverage).to have_attributes(
        project_id: pipeline.project.id,
        last_pipeline_id: pipeline.id,
        ref: pipeline.ref,
        name: karma_job.name,
        coverage: karma_job.coverage,
        date: pipeline.created_at.to_date
      )
    end

    expect(DailyCodeCoverage.find_by(name: 'extra')).to be_nil
  end

  context 'when there is an existing daily code coverage for the matching date, project, ref, and name' do
    let!(:new_pipeline) do
      create(
        :ci_pipeline,
        project: pipeline.project,
        ref: pipeline.ref,
        created_at: '2020-02-06 00:02:20'
      )
    end
    let!(:new_rspec_job) { create(:ci_build, pipeline: new_pipeline, name: 'rspec', coverage: 84) }
    let!(:new_karma_job) { create(:ci_build, pipeline: new_pipeline, name: 'karma', coverage: 92) }

    before do
      # Create the existing daily code coverage records
      described_class.new.execute(pipeline)
    end

    it "updates the existing record's coverage value and last_pipeline_id" do
      rspec_coverage = DailyCodeCoverage.find_by(name: 'rspec')
      karma_coverage = DailyCodeCoverage.find_by(name: 'karma')

      # Bump up the coverage values
      described_class.new.execute(new_pipeline)

      rspec_coverage.reload
      karma_coverage.reload

      expect(rspec_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        coverage: new_rspec_job.coverage
      )

      expect(karma_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        coverage: new_karma_job.coverage
      )
    end
  end

  context 'when the ID of the given pipeline is older than the last_pipeline_id' do
    let!(:new_pipeline) do
      create(
        :ci_pipeline,
        project: pipeline.project,
        ref: pipeline.ref,
        created_at: '2020-02-06 00:02:20'
      )
    end
    let!(:new_rspec_job) { create(:ci_build, pipeline: new_pipeline, name: 'rspec', coverage: 84) }
    let!(:new_karma_job) { create(:ci_build, pipeline: new_pipeline, name: 'karma', coverage: 92) }

    before do
      # Create the existing daily code coverage records
      # but in this case, for the newer pipeline first.
      described_class.new.execute(new_pipeline)
    end

    it 'does not update the existing daily code coverage records' do
      rspec_coverage = DailyCodeCoverage.find_by(name: 'rspec')
      karma_coverage = DailyCodeCoverage.find_by(name: 'karma')

      # Run another one but for the older pipeline.
      # This simulates the scenario wherein the success worker
      # of an older pipeline, for some network hiccup, was delayed
      # and only got executed right after the newer pipeline's success worker.
      # In this case, we don't want to bump the coverage value with an older one.
      described_class.new.execute(pipeline)

      rspec_coverage.reload
      karma_coverage.reload

      expect(rspec_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        coverage: new_rspec_job.coverage
      )

      expect(karma_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        coverage: new_karma_job.coverage
      )
    end
  end
end
