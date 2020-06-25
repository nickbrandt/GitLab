# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReindexingTask, type: :model do
  let(:completed_task) { create(:reindexing_task, stage: :success) }
  let(:running_task) { create(:reindexing_task) }

  it 'only allows one running task at a time' do
    expect(running_task).to be_valid
    expect(completed_task).to be_valid

    expect(build(:reindexing_task)).not_to be_valid
  end
end
