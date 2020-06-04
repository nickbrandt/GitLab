# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RequirementsManagement::UpdateRequirementService do
  let_it_be(:project) { create(:project)}
  let_it_be(:user) { create(:user) }
  let_it_be(:requirement) { create(:requirement, project: project) }
  let(:params) do
    {
      title: 'foo',
      state: 'archived',
      created_at: 2.days.ago,
      author_id: create(:user).id
    }
  end

  subject { described_class.new(project, user, params).execute(requirement) }

  describe '#execute' do
    before do
      stub_licensed_features(requirements: true)
    end

    context 'when user can update requirements' do
      before do
        project.add_reporter(user)
      end

      it 'updates the requirement with only permitted params', :aggregate_failures do
        is_expected.to have_attributes(
          errors: be_empty,
          title: params[:title],
          state: params[:state]
        )
        is_expected.not_to have_attributes(
          created_at: params[:created_at],
          author_id: params[:author_id]
        )
      end
    end

    context 'when user is not allowed to update requirements' do
      it 'raises an exception' do
        expect { subject }.to raise_exception(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
