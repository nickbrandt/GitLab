# frozen_string_literal: true

require 'spec_helper'

describe PlannedProjectDestroyWorker do
  describe "#perform" do
    subject(:worker) { described_class.new }

    let(:user) { create(:user)}
    let(:project) { create(:project, deleting_user: user) }

    it 'executes destroying project' do
      service = instance_double(Projects::PlannedDestroyService)
      expect(service).to receive(:execute)
      expect(Projects::PlannedDestroyService).to receive(:new).with(project, user).and_return(service)

      worker.perform(project.id)
    end
  end
end
