# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeOwners::File do
  include FakeBlobHelpers

  let(:project) { build(:project) }
  let(:file_content) do
    File.read(Rails.root.join('ee', 'spec', 'fixtures', 'codeowners_example'))
  end

  let(:blob) { fake_blob(path: 'CODEOWNERS', data: file_content) }

  subject(:file) { described_class.new(blob) }

  before do
    stub_feature_flags(sectional_codeowners: false)
  end

  describe '#parsed_data' do
    def owner_line(pattern)
      file.parsed_data[pattern].owner_line
    end

    it 'parses all the required lines' do
      expected_patterns = [
        '/**/*', '/**/#file_with_pound.rb', '/**/*.rb', '/**/CODEOWNERS', '/**/LICENSE', '/docs/**/*',
        '/docs/*', '/config/**/*', '/**/lib/**/*', '/**/path with spaces/**/*'
      ]

      expect(file.parsed_data.keys)
        .to contain_exactly(*expected_patterns)
    end

    it 'allows usernames and emails' do
      expect(owner_line('/**/LICENSE')).to include('legal', 'janedoe@gitlab.com')
    end

    context "when feature flag `:sectional_codeowners` is enabled" do
      using RSpec::Parameterized::TableSyntax

      before do
        stub_feature_flags(sectional_codeowners: true)
      end

      shared_examples_for "creates expected parsed results" do
        it "is a hash sorted by sections without duplicates" do
          data = file.parsed_data

          expect(data.keys.length).to eq(3)
          expect(data.keys).to contain_exactly("codeowners", "Documentation", "Database")
        end

        where(:section, :patterns, :owners) do
          "codeowners"    | ["/**/ee/**/*"] | ["@gl-admin"]
          "Documentation" | ["/**/README.md", "/**/ee/docs", "/**/docs"] | ["@gl-docs"]
          "Database"      | ["/**/README.md", "/**/model/db"] | ["@gl-database"]
        end

        with_them do
          it "assigns the correct paths to each section" do
            expect(file.parsed_data[section].keys).to contain_exactly(*patterns)
            expect(file.parsed_data[section].values.detect { |entry| entry.section != section }).to be_nil
          end

          it "assigns the correct owners for each entry" do
            extracted_owners = file.parsed_data[section].values.collect(&:owner_line).uniq
            expect(extracted_owners).to contain_exactly(*owners)
          end
        end
      end

      it "passes the call to #get_parsed_sectional_data" do
        expect(file).to receive(:get_parsed_sectional_data)

        file.parsed_data
      end

      it "populates a hash with a single default section" do
        data = file.parsed_data

        expect(data.keys.length).to eq(1)
        expect(data.keys).to contain_exactly(::Gitlab::CodeOwners::Entry::DEFAULT_SECTION)
      end

      context "when CODEOWNERS file contains multiple sections" do
        let(:file_content) do
          File.read(Rails.root.join("ee", "spec", "fixtures", "sectional_codeowners_example"))
        end

        it_behaves_like "creates expected parsed results"
      end

      context "when CODEOWNERS file contains multiple sections with mixed-case names" do
        let(:file_content) do
          File.read(Rails.root.join("ee", "spec", "fixtures", "mixed_case_sectional_codeowners_example"))
        end

        it_behaves_like "creates expected parsed results"
      end
    end
  end

  describe '#empty?' do
    subject { file.empty? }

    it { is_expected.to be(false) }

    context 'when there is no content' do
      let(:file_content) { "" }

      it { is_expected.to be(true) }
    end

    context 'when the file is binary' do
      let(:blob) { fake_blob(binary: true) }

      it { is_expected.to be(true) }
    end

    context 'when the file did not exist' do
      let(:blob) { nil }

      it { is_expected.to be(true) }
    end
  end

  describe "#path" do
    context "when the blob exists" do
      it "returns the path to the file" do
        expect(subject.path).to eq(blob.path)
      end
    end

    context "when the blob is nil" do
      let(:blob) { nil }

      it "returns nil" do
        expect(subject.path).to be_nil
      end
    end
  end

  describe '#entry_for_path' do
    context 'for a path without matches' do
      let(:file_content) do
        <<~CONTENT
        # Simulating a CODOWNERS without entries
        CONTENT
      end

      it 'returns an nil for an unmatched path' do
        entry = file.entry_for_path('no_matches')

        expect(entry).to be_nil
      end
    end

    it 'matches random files to a pattern' do
      entry = file.entry_for_path('app/assets/something.vue')

      expect(entry.pattern).to eq('*')
      expect(entry.owner_line).to include('default-codeowner')
    end

    it 'uses the last pattern if multiple patterns match' do
      entry = file.entry_for_path('hello.rb')

      expect(entry.pattern).to eq('*.rb')
      expect(entry.owner_line).to eq('@ruby-owner')
    end

    it 'returns the usernames for a file matching a pattern with a glob' do
      entry = file.entry_for_path('app/models/repository.rb')

      expect(entry.owner_line).to eq('@ruby-owner')
    end

    it 'allows specifying multiple users' do
      entry = file.entry_for_path('CODEOWNERS')

      expect(entry.owner_line).to include('multiple', 'owners', 'tab-separated')
    end

    it 'returns emails and usernames for a matched pattern' do
      entry = file.entry_for_path('LICENSE')

      expect(entry.owner_line).to include('legal', 'janedoe@gitlab.com')
    end

    it 'allows escaping the pound sign used for comments' do
      entry = file.entry_for_path('examples/#file_with_pound.rb')

      expect(entry.owner_line).to include('owner-file-with-pound')
    end

    it 'returns the usernames for a file nested in a directory' do
      entry = file.entry_for_path('docs/projects/index.md')

      expect(entry.owner_line).to include('all-docs')
    end

    it 'returns the usernames for a pattern matched with a glob in a folder' do
      entry = file.entry_for_path('docs/index.md')

      expect(entry.owner_line).to include('root-docs')
    end

    it 'allows matching files nested anywhere in the repository', :aggregate_failures do
      lib_entry = file.entry_for_path('lib/gitlab/git/repository.rb')
      other_lib_entry = file.entry_for_path('ee/lib/gitlab/git/repository.rb')

      expect(lib_entry.owner_line).to include('lib-owner')
      expect(other_lib_entry.owner_line).to include('lib-owner')
    end

    it 'allows allows limiting the matching files to the root of the repository', :aggregate_failures do
      config_entry = file.entry_for_path('config/database.yml')
      other_config_entry = file.entry_for_path('other/config/database.yml')

      expect(config_entry.owner_line).to include('config-owner')
      expect(other_config_entry.owner_line).to eq('@default-codeowner')
    end

    it 'correctly matches paths with spaces' do
      entry = file.entry_for_path('path with spaces/README.md')

      expect(entry.owner_line).to eq('@space-owner')
    end

    context 'paths with whitespaces and username lookalikes' do
      let(:file_content) do
        'a/weird\ path\ with/\ @username\ /\ and-email@lookalikes.com\ / @user-1 email@gitlab.org @user-2'
      end

      it 'parses correctly' do
        entry = file.entry_for_path('a/weird path with/ @username / and-email@lookalikes.com /test.rb')

        expect(entry.owner_line).to include('user-1', 'user-2', 'email@gitlab.org')
        expect(entry.owner_line).not_to include('username', 'and-email@lookalikes.com')
      end
    end

    context 'a glob on the root directory' do
      let(:file_content) do
        '/* @user-1 @user-2'
      end

      it 'matches files in the root directory' do
        entry = file.entry_for_path('README.md')

        expect(entry.owner_line).to include('user-1', 'user-2')
      end

      it 'does not match nested files' do
        entry = file.entry_for_path('nested/path/README.md')

        expect(entry).to be_nil
      end
    end

    context 'partial matches' do
      let(:file_content) do
        'foo/* @user-1 @user-2'
      end

      it 'does not match a file in a folder that looks the same' do
        entry = file.entry_for_path('fufoo/bar')

        expect(entry).to be_nil
      end

      it 'matches the file in any folder' do
        expect(file.entry_for_path('baz/foo/bar').owner_line).to include('user-1', 'user-2')
        expect(file.entry_for_path('/foo/bar').owner_line).to include('user-1', 'user-2')
      end
    end
  end
end
