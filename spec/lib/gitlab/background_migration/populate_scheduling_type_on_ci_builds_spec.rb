# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::PopulateSchedulingTypeOnCiBuilds, :migration, schema: 20200227122739 do
  let(:builds) { table(:ci_builds) }
  let(:build_needs) { table(:ci_build_needs) }

  let!(:build_without_needs) { builds.create!(id: 101, type: 'Ci::Build') }
  let!(:build_with_needs) do
    builds.create!(id: 102, type: 'Ci::Build').tap do |build|
      build_needs.create!(build_id: build.id, name: 'build101')
    end
  end
  let!(:bridge_without_needs) { builds.create!(id: 103, type: 'Ci::Bridge') }

  let!(:generic_commit_status) { builds.create!(id: 104, type: 'GenericCommitStatus') }
  let!(:build_out_of_range) { builds.create!(id: 105, type: 'Ci::Build') }

  it 'populates scheduling_type of ci_builds / ci_bridges that have nil scheduling_type in id range' do
    subject.perform(101, 104)

    expect(build_without_needs.reload.scheduling_type).to eq(0)
    expect(build_with_needs.reload.scheduling_type).to eq(1)
    expect(bridge_without_needs.reload.scheduling_type).to eq(0)

    expect(generic_commit_status.reload.scheduling_type).to be_nil
    expect(build_out_of_range.reload.scheduling_type).to be_nil
  end
end
