# frozen_string_literal: true

require 'spec_helper'

describe Projects::DesignsController do
  let(:project) { create(:project, :public) }
  let(:issue) { create(:issue, project: project) }
  let(:design) { create(:design, :with_file, issue: issue) }

  before do
    stub_licensed_features(design_management: true)
  end

  describe 'GET #show' do
    subject do
      get(:show,
        params: {
          namespace_id: project.namespace,
          project_id: project,
          id: design.id,
          ref: 'HEAD'
      })
    end

    it 'serves the file using workhorse' do
      subject

      expect(response).to have_gitlab_http_status(200)
      expect(response.header['Content-Disposition']).to eq('inline')
      expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
      expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
    end

    it_behaves_like 'a controller that can serve LFS files' do
      let(:design) { create(:design, :with_lfs_file, issue: issue) }
      let(:lfs_oid) { project.design_repository.blob_at('HEAD', design.full_path).lfs_oid }
      let(:filename) { design.filename }
      let(:filepath) { design.full_path }
    end
  end
end
