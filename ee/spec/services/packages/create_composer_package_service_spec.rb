# frozen_string_literal: true
require 'spec_helper'

describe Packages::CreateComposerPackageService do
  let(:current_user) { create(:user) }
  let(:project) { create(:project) }

  let(:params_hash) do
    {
      'name' => 'ochorocho/gitlab-composer',
      'version' => '2.0.0',
      'version_data' => JSON.parse(File.read('ee/spec/fixtures/composer/version-2.0.0.json')).first[1],
      'shasum' => '',
      'attachments' => [{
        'contents' => 'aGVsbG8K',
        'size' => 8,
        'file_sha1' => 'c775f1f5cc34f272e25c17b62e1932d0ca5087f8',
        'filename' => 'ochorocho-gitlab-composer-2.0.0-19c3ec.tar'
      }, {
        'contents' => 'aGVsbG8K',
        'size' => 8,
        'file_sha1' => 'c775f1f5cc34f272e25c17b62e1932d0ca5087f8',
        'filename' => 'version-2.0.0.json'
      }]
    }
  end

  describe '#execute' do
    it 'creates a new package with tar archive and json meta files ' do
      params = params_hash.to_json
      package = described_class.new(project, current_user, params).execute

      expect(params_hash['attachments']).to match(package)
    end
  end
end
