# frozen_string_literal: true

require 'spec_helper'

describe Ci::PipelineSchedule do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_pipeline_schedule) }
  end
end
