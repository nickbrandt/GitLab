# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::WordDiff::Parser do
  include RepoHelpers

  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse(diff.lines).to_a }

    let(:diff) do
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
  end
end
