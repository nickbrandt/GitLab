# frozen_string_literal: true

require 'spec_helper'

describe AnalyticsWorker do
  before do
    test_analytics_task_class = Class.new do
      def perform(*args)
        args
      end
    end
    stub_const('TestAnalyticsTask', test_analytics_task_class)
  end

  describe '#perform' do
    it 'executes specified service class with given arguments' do
      expect_any_instance_of(TestAnalyticsTask).to receive(:perform).with('arg1', 'arg2', 'arg3')
      subject.perform('TestAnalyticsTask', %w[arg1 arg2 arg3])
    end
  end
end
