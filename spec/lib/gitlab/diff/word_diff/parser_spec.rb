# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::WordDiff::Parser do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:parser) { described_class.new }

  describe '#parse' do
    let(:diff) do
      <<EOF
@@ -1,14 +1,13 @@
~
 Unchanged line
~
~
-Old change
+New addition
  unchanged content
~
+First change
  same same same
-removed
+added
  end of the line
~
~
EOF
    end

    before do
      @lines = parser.parse(diff.lines).to_a
    end

    describe 'lines' do
      it { expect(@lines).to be }
    end
  end
end
