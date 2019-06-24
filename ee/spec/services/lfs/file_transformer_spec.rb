# frozen_string_literal: true

require "spec_helper"

describe Lfs::FileTransformer do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:file_content) { 'Test file content' }
  let(:branch_name) { 'lfs' }

  subject { described_class.new(project, repository, branch_name) }

  describe '#new_file' do
    before do
      allow(project).to receive(:lfs_enabled?).and_return(true)

      file.write(file_content)
      file.rewind
    end

    after do
      file.unlink
    end

    context 'when repository is a design repository' do
      let(:file_path) { "/#{DesignManagement.designs_directory}/test_file.lfs" }
      let(:file) { Tempfile.new(file_path) }
      let(:repository) { project.design_repository }

      it "creates an LfsObject with the file's content" do
        subject.new_file(file_path, file)

        expect(LfsObject.last.file.read).to eq(file_content)
      end
    end
  end
end
