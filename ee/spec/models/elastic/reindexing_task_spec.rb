# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ReindexingTask, type: :model do
  it 'only allows one running task at a time' do
    expect { create(:elastic_reindexing_task, state: :success) }.not_to raise_error
    expect { create(:elastic_reindexing_task) }.not_to raise_error
    expect { create(:elastic_reindexing_task) }.to raise_error(/violates unique constraint/)
  end

  it 'sets in_progress flag' do
    task = create(:elastic_reindexing_task, state: :success)
    expect(task.in_progress).to eq(false)

    task.update!(state: :reindexing)
    expect(task.in_progress).to eq(true)
  end
end
