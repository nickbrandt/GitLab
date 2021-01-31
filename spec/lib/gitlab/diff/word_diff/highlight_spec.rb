# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::WordDiff::Highlight do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  let(:commit) { project.commit(sample_commit.id) }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: project.repository, word_diff: true) }

  before do
    diff.diff = <<EOF
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

  describe '#highlight' do
    context "with a diff file" do
      let(:subject) { described_class.new(diff_file, repository: project.repository).highlight }

      it { is_expected.to be }
    end
  end
end
