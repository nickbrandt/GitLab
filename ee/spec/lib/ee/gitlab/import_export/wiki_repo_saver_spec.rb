# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::WikiRepoSaver do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) do
    create(:group, :wiki_repo).tap do |g|
      g.add_owner(user)
    end
  end

  let(:exportable) { group }
  let(:shared) { Gitlab::ImportExport::Shared.new(group) }

  subject { described_class.new(exportable: exportable, shared: shared) }

  describe 'bundles a group wiki Git repo' do
    let!(:group_wiki) { GroupWiki.new(group, user) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec" }

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end

      group_wiki.create_page('index', 'test content')
      group.wiki.repository.expire_status_cache
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'bundles the repo successfully' do
      expect(subject.save).to be true
      expect(File.exist?(subject.send(:bundle_full_path))).to eq true
    end

    context 'when the repo is empty' do
      let!(:group) { create(:group) }

      it 'bundles the repo successfully' do
        expect(subject.save).to be true
      end
    end
  end

  describe '#bundle_filename' do
    context 'when exportable is a group' do
      it 'returns the right filename for group wikis' do
        expect(subject.send(:bundle_filename)).to eq ::Gitlab::ImportExport.group_wiki_repo_bundle_filename(exportable.id)
      end
    end

    context 'when exportable is a project' do
      let(:exportable) { build_stubbed(:project) }

      it 'returns the right filename for project wikis' do
        expect(subject.send(:bundle_filename)).to eq ::Gitlab::ImportExport.wiki_repo_bundle_filename
      end
    end
  end
end
