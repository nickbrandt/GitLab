# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectsBatchCounting do
  describe '.execute_batch_counting' do
    subject do
      Class.new do
        include ::API::ProjectsBatchCounting
      end
    end

    let(:projects) { create_list(:project, 2) }
    let(:count_service) { double }

    it 'counts forks' do
      allow(::Projects::BatchForksCountService).to receive(:new).with(projects).and_return(count_service)

      expect(count_service).to receive(:refresh_cache)

      subject.execute_batch_counting(projects)
    end

    it 'counts open issues' do
      allow(::Projects::BatchOpenIssuesCountService).to receive(:new).with(projects).and_return(count_service)

      expect(count_service).to receive(:refresh_cache)

      subject.execute_batch_counting(projects)
    end

    context 'custom fork counting' do
      subject do
        Class.new do
          include ::API::ProjectsBatchCounting
          def self.forks_counting_projects(projects)
            [projects.first]
          end
        end
      end

      it 'counts forks for other projects' do
        allow(::Projects::BatchForksCountService).to receive(:new).with([projects.first]).and_return(count_service)

        expect(count_service).to receive(:refresh_cache)

        subject.execute_batch_counting(projects)
      end
    end
  end
end
