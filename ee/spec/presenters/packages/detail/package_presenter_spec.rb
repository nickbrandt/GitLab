# frozen_string_literal: true

require 'spec_helper'

describe ::Packages::Detail::PackagePresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }
  let_it_be(:package) { create(:npm_package, :with_build, project: project) }
  let(:presenter) { described_class.new(package) }

  let_it_be(:user_info) { { name: user.name, avatar_url: user.avatar_url } }
  let!(:expected_package_files) do
    npm_file = package.package_files.first
    [{
      created_at: npm_file.created_at,
      download_path: npm_file.download_path,
      file_name: npm_file.file_name,
      size: npm_file.size
    }]
  end
  let(:pipeline_info) do
    pipeline = package.build_info.pipeline
    {
      created_at: pipeline.created_at,
      id: pipeline.id,
      sha: pipeline.sha,
      ref: pipeline.ref,
      git_commit_message: pipeline.git_commit_message,
      user: user_info,
      project: {
        name: pipeline.project.name,
        web_url: pipeline.project.web_url
      }
    }
  end
  let!(:expected_package_details) do
    {
      created_at: package.created_at,
      name: package.name,
      package_files: expected_package_files,
      package_type: package.package_type,
      project_id: package.project_id,
      tags: package.tags.as_json,
      updated_at: package.updated_at,
      version: package.version
    }
  end

  context 'detail_view' do
    context 'with build_info' do
      let!(:package) { create(:npm_package, :with_build, project: project) }

      it 'returns details with pipeline' do
        expected_package_details[:pipeline] = pipeline_info

        expect(presenter.detail_view).to eq expected_package_details
      end
    end

    context 'without build info' do
      let!(:package) { create(:npm_package, project: project) }

      it 'returns details without pipeline' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end
  end

  it 'build_package_file_view returns correct file data' do
    package_files_result = package.package_files.map { |pf| presenter.build_package_file_view(pf) }

    expect(package_files_result).to eq expected_package_files
  end

  context 'build_pipeline_info' do
    it 'returns correct data when there is pipeline_info' do
      expect(presenter.build_pipeline_info(package.build_info.pipeline)).to eq pipeline_info
    end
  end

  context 'build_user_info' do
    it 'returns correct data when there is a user' do
      expect(presenter.build_user_info(package.build_info.pipeline.user)).to eq user_info
    end

    it 'returns nil when there is not a user' do
      expect(presenter.build_user_info(nil)).to eq nil
    end
  end
end
