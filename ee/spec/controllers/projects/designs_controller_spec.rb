# frozen_string_literal: true

require 'spec_helper'

describe Projects::DesignsController do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let(:file) { fixture_file_upload('spec/fixtures/dk.png', '`/png') }
  let(:lfs_pointer) { Gitlab::Git::LfsPointerFile.new(file.read) }
  let(:design) { create(:design, :with_lfs_file, file: lfs_pointer.pointer, issue: issue) }
  let(:filename) { design.filename }

  before do
    enable_design_management
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

    # For security, .svg images should only ever be served with Content-Disposition: attachment.
    # If these specs ever fail we must assess whether we should be serving svg images.
    # See https://gitlab.com/gitlab-org/gitlab/issues/12771
    describe 'Response headers' do
      it 'serves LFS files with `Content-Disposition: attachment`' do
        lfs_object = create(:lfs_object, file: file, oid: lfs_pointer.sha256, size: lfs_pointer.size)
        create(:lfs_objects_project, project: project, lfs_object: lfs_object, repository_type: :design)

        subject

        expect(response.header['Content-Disposition']).to eq(%Q(attachment; filename*=UTF-8''#{filename}; filename=\"#{filename}\"))
      end

      context 'when the design is not an LFS file' do
        let(:design) { create(:design, :with_file, issue: issue) }

        it 'serves files with `Content-Disposition: attachment`' do
          subject

          expect(response.header['Content-Disposition']).to eq('attachment')
        end

        it 'serves files with Workhorse' do
          subject

          expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq "true"
          expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        end
      end
    end

    # Pass `skip_lfs_disabled_tests: true` to this shared example to disable
    # the test scenarios for when LFS is disabled globally.
    #
    # When LFS is disabled then the design management feature also becomes disabled.
    # When the feature is disabled, the `authorize :read_design` check within the
    # controller will never authorize the user. Therefore #show will return a 403 and
    # we cannot test the data that it serves.
    it_behaves_like 'a controller that can serve LFS files', skip_lfs_disabled_tests: true do
      let(:lfs_oid) { project.design_repository.blob_at('HEAD', design.full_path).lfs_oid }
      let(:filepath) { design.full_path }
    end
  end
end
