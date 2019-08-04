# frozen_string_literal: true

require 'spec_helper'

describe CycleAnalytics::StageListService do
  let(:project) { build(:project, :empty_repo) }

  it 'returns the default stages as in-memory objects if customizable stages are not allowed' do
    service = described_class.new(parent: project, allowed_to_customize_stages: false)

    stages = service.execute

    stage_names = stages.map(&:name)
    expect(stage_names).to eq(Gitlab::CycleAnalytics::DefaultStages.all.map { |p| p[:name] })

    stage_ids = stages.map(&:id)
    expect(stage_ids.all?(&:nil?)).to eq(true)
  end

  it 'persists and returns the default stages as records if customizable stages are allowed' do
    service = described_class.new(parent: project, allowed_to_customize_stages: true)

    stages = service.execute

    expect(stages.all?(&:persisted?)).to eq(true)
  end

  it 'returns the persisted stages' do
    stage = create(:cycle_analytics_project_stage, project: project)

    service = described_class.new(parent: project)

    stages = service.execute
    expect(stages).to eq([stage])
  end

  it 'returns items in order' do
    project = create(:project)

    last = create(:cycle_analytics_project_stage, project: project, relative_position: 2)
    first = create(:cycle_analytics_project_stage, project: project, relative_position: 1)

    service = described_class.new(parent: project)
    stages = service.execute

    expect(stages).to eq([first, last])
  end
end
