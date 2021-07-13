# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppSec::Dast::ProfileScheduleWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform }

    it 'executes a RunProfileSchedulesService' do
      expect_next_instance_of(AppSec::Dast::ProfileSchedules::RunService) do |service|
        expect(service).to receive(:perform)
      end

      subject
    end
  end
end
