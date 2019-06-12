# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::BaseService do
  include ProjectForksHelper

  subject { MergeRequests::CreateService.new(project, project.owner, params) }

  let(:project) { create(:project, :repository) }
  let(:params_filtering_service) { double(:params_filtering_service) }
  let(:params) do
    {
      title: 'Awesome merge_request',
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master'
    }
  end

  describe '#filter_params' do
    context 'filter users and groups' do
      before do
        allow(subject).to receive(:execute_hooks)
      end

      it 'calls ParamsFilteringService' do
        expect(ApprovalRules::ParamsFilteringService).to receive(:new).with(
          an_instance_of(MergeRequest),
          project.owner,
          params
        ).and_return(params_filtering_service)
        expect(params_filtering_service).to receive(:execute).and_return(params)

        subject.execute
      end
    end
  end
end
