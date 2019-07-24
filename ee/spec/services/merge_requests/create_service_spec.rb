# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::CreateService do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }

  subject(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with blocking merge requests' do
      let(:params) { { title: 'Blocked MR', source_branch: 'feature', target_branch: 'master' } }

      it 'delegates to MergeRequests::UpdateBlocksService' do
        expect(MergeRequests::UpdateBlocksService)
          .to receive(:extract_params!)
          .and_return(:extracted_params)

        expect_next_instance_of(MergeRequests::UpdateBlocksService) do |block_service|
          expect(block_service.merge_request.title).to eq('Blocked MR')
          expect(block_service.current_user).to eq(user)
          expect(block_service.params).to eq(:extracted_params)

          expect(block_service).to receive(:execute)
        end

        service.execute
      end
    end
  end
end
