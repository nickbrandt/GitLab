# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeOwners::Loader do
  include FakeBlobHelpers
  set(:group) { create(:group) }
  set(:project) { create(:project, namespace: group) }
  subject(:loader) { described_class.new(project, 'with-codeowners', paths) }

  let!(:owner_1) { create(:user, username: 'owner-1') }
  let!(:email_owner) { create(:user, username: 'owner-2') }
  let!(:owner_3) { create(:user, username: 'owner-3') }
  let!(:documentation_owner) { create(:user, username: 'documentation-owner') }
  let!(:test_owner) { create(:user, username: 'test-owner') }
  let(:codeowner_content) do
    <<~CODEOWNERS
    docs/* @documentation-owner
    docs/CODEOWNERS @owner-1 owner2@gitlab.org @owner-3 @documentation-owner
    spec/* @test-owner
    CODEOWNERS
  end
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
  let(:paths) { 'docs/CODEOWNERS' }

  before do
    project.add_developer(owner_1)
    project.add_developer(email_owner)
    project.add_developer(documentation_owner)
    project.add_developer(test_owner)

    create(:email, user: email_owner, email: 'owner2@gitlab.org')

    allow(project.repository).to receive(:code_owners_blob).and_return(codeowner_blob)
  end

  describe '#entries' do
    let(:expected_entry) { Gitlab::CodeOwners::Entry.new('docs/CODEOWNERS', '@owner-1 owner2@gitlab.org @owner-3 @documentation-owner') }
    let(:first_entry) { loader.entries.first }

    it 'returns entries for the matched line' do
      expect(loader.entries).to contain_exactly(expected_entry)
    end

    it 'loads all users that are members of the project into the entry' do
      expect(first_entry.users).to contain_exactly(owner_1, email_owner, documentation_owner)
    end

    it 'does not load non members of the project into the entry' do
      expect(first_entry.users).not_to include(owner_3)
    end

    it 'loads group members of the project into the entry' do
      group.add_developer(owner_3)

      expect(first_entry.users).to include(owner_3)
    end

    context 'for multiple paths' do
      let(:paths) { ['docs/CODEOWNERS', 'spec/loader_spec.rb', 'spec/entry_spec.rb'] }

      it 'loads 2 entries' do
        other_entry = Gitlab::CodeOwners::Entry.new('spec/*', '@test-owner')

        expect(loader.entries).to contain_exactly(expected_entry, other_entry)
      end

      it 'only performs 2 query for users' do
        # One query for users, one for the emails to later divide them across the
        # entries
        expect { loader.entries }.not_to exceed_query_limit(2)
      end
    end

    context 'with the request store', :request_store do
      it 'only calls out to the repository once' do
        expect(project.repository).to receive(:code_owners_blob).once

        2.times { loader.entries }
      end

      it 'only processes the file once' do
        code_owners_file = loader.__send__(:code_owners_file)

        expect(code_owners_file).to receive(:get_parsed_data).once.and_call_original

        2.times { loader.entries }
      end
    end
  end

  describe '#members' do
    it 'returns users mentioned for the passed path' do
      expect(loader.members).to contain_exactly(owner_1, email_owner, documentation_owner)
    end
  end

  describe '#empty_code_owners?' do
    context 'when file does not exist' do
      let(:codeowner_blob) { nil }

      it 'returns true' do
        expect(loader.empty_code_owners?).to eq(true)
      end
    end

    context 'when file is empty' do
      let(:codeowner_content) { '' }

      it 'returns true' do
        expect(loader.empty_code_owners?).to eq(true)
      end
    end

    context 'when file content exists' do
      it 'returns false' do
        expect(loader.empty_code_owners?).to eq(false)
      end
    end
  end
end
