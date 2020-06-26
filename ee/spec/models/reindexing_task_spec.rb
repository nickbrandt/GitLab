# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReindexingTask, type: :model do
  it 'only allows one running task at a time' do
    expect { create(:reindexing_task, stage: :success) }.not_to raise_error
    expect { create(:reindexing_task) }.not_to raise_error
    expect { create(:reindexing_task) }.to raise_error(/violates unique constraint/)
  end
end
