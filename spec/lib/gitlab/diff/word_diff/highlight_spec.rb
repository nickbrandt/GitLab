# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::WordDiff::Highlight do
  include RepoHelpers

  subject(:diff_highlight) { described_class.new(diff_file, repository: project.repository) }

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: project.repository, word_diff: true) }
  let(:diff_content) do
    <<~EOF
    @@ -1,14 +1,13 @@
    ~
     Unchanged line
    ~
    ~
    -Old change
    +New addition
      unchanged content
    ~
    @@ -50,14 +50,13 @@
    +First change
      same same same_
    -removed_
    +added_
     end of the line
    ~
    ~
    EOF
  end

  before do
    diff.new_path = 'test.txt'
    diff.diff = diff_content
  end

  describe '#highlight' do
    subject { diff_highlight.highlight }

    it 'returns a collection of lines' do
      diff_lines = subject

      expect(diff_lines.count).to eq(7)

      expect(diff_lines.map(&:to_hash)).to match_array(
        [
          a_hash_including(index: 0, old_pos: 1, new_pos: 1, text: '', type: 'word-diff'),
          a_hash_including(index: 1, old_pos: 2, new_pos: 2, text: 'Unchanged line', type: 'word-diff'),
          a_hash_including(index: 2, old_pos: 3, new_pos: 3, text: '', type: 'word-diff'),
          a_hash_including(index: 3, old_pos: 4, new_pos: 4, text: 'Old changeNew addition unchanged content', type: 'word-diff'),
          a_hash_including(index: 4, old_pos: 50, new_pos: 50, text: '@@ -50,14 +50,13 @@', type: 'match'),
          a_hash_including(index: 5, old_pos: 50, new_pos: 50, text: 'First change same same same_removed_added_end of the line', type: 'word-diff'),
          a_hash_including(index: 6, old_pos: 51, new_pos: 51, text: '', type: 'word-diff')
        ]
      )
    end

    it 'populates diff lines with highlighted content' do
      diff_lines = subject

      expect(diff_lines.count).to eq(7)

      expect(diff_lines.map(&:rich_text)).to match_array(
        [
          "<span id=\"LC1\" class=\"line\" lang=\"plaintext\"></span>\n",
          "<span id=\"LC2\" class=\"line\" lang=\"plaintext\">Unchanged line</span>\n",
          "<span id=\"LC3\" class=\"line\" lang=\"plaintext\"></span>\n",
          "<span id=\"LC4\" class=\"line\" lang=\"plaintext\"><span class=\"idiff removed\">Old change</span><span class=\"idiff added\">New addition</span> unchanged content</span>\n",
          nil,
          "<span id=\"LC6\" class=\"line\" lang=\"plaintext\"><span class=\"idiff added\">First change</span> same same same_<span class=\"idiff removed\">removed_</span><span class=\"idiff added\">added_</span>end of the line</span>",
          ""
        ]
      )
    end
  end
end
