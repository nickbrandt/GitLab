# frozen_string_literal: true

require 'fast_spec_helper'

describe Quality::TestFileFinder do
  let(:file) { 'app/finders/admin/projects_finder.rb' }
  let(:test_files) { ['spec/finders/admin/projects_finder_spec.rb'] }

  subject { Quality::TestFileFinder.new(file) }

  shared_examples 'finding matching test files' do
    it 'returns matching test files' do
      expect(subject.test_files).to match_array(test_files)
    end
  end

  shared_examples 'not finding a matching test file' do
    it 'returns empty array' do
      expect(subject.test_files).to be_empty
    end
  end

  describe '#test_files' do
    it_behaves_like 'finding matching test files'

    context 'when given non .rb files' do
      let(:file) { 'app/assets/images/emoji.png' }

      it_behaves_like 'not finding a matching test file'
    end

    context 'when given file in app/' do
      let(:file) { 'app/finders/admin/projects_finder.rb' }
      let(:test_files) { ['spec/finders/admin/projects_finder_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given file in lib/' do
      let(:file) { 'lib/banzai/color_parser.rb' }
      let(:test_files) { ['spec/lib/banzai/color_parser_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given a test file' do
      let(:file) { 'spec/lib/banzai/color_parser_spec.rb' }
      let(:test_files) { ['spec/lib/banzai/color_parser_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given an ee app file' do
      let(:file) { 'ee/app/models/analytics/cycle_analytics/group_level.rb' }
      let(:test_files) { ['ee/spec/models/analytics/cycle_analytics/group_level_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given an ee module file' do
      let(:file) { 'ee/app/models/ee/user.rb' }
      let(:test_files) { ['spec/app/models/user_spec.rb', 'ee/spec/models/ee/user_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given an ee lib file' do
      let(:file) { 'ee/lib/flipper_session.rb' }
      let(:test_files) { ['ee/spec/lib/flipper_session_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given an ee test file' do
      let(:file) { 'ee/spec/models/container_registry/event_spec.rb' }
      let(:test_files) { ['ee/spec/models/container_registry/event_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'when given an ee module test file' do
      let(:file) { 'ee/spec/models/ee/appearance_spec.rb' }
      let(:test_files) { ['ee/spec/models/ee/appearance_spec.rb', 'spec/models/appearance_spec.rb'] }

      it_behaves_like 'finding matching test files'
    end

    context 'with foss_test_only: true' do
      let(:file) { 'ee/app/models/ee/user.rb' }
      let(:test_files) { ['spec/app/models/user_spec.rb'] }

      subject { Quality::TestFileFinder.new(file, foss_test_only: true) }

      it 'excludes matching ee test files' do
        expect(subject.test_files).to match_array(test_files)
      end
    end
  end
end
