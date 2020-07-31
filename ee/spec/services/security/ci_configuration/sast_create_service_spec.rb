# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastCreateService do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }

    subject(:result) { described_class.new(project, user, params).execute }

    before do
      project.add_developer(user)
    end

    context 'with no parameters' do
      let(:params) { {} }

      it 'returns the path to create a new merge request' do
        expect(result[:status]).to eq(:success)
        expect(result[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
      end
    end
  end
end
