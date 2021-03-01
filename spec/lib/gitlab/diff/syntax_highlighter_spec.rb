# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Diff::SyntaxHighlighter do
  include RepoHelpers

  subject(:syntax_highlighter) { described_class.new(diff_file) }

  let_it_be(:project) { create(:project, :repository) }
  let(:commit) { project.commit }
  let(:diff) { commit.raw_diffs.first }
  let(:diff_file) { Gitlab::Diff::File.new(diff, diff_refs: commit.diff_refs, repository: project.repository) }
  let(:diff_lines) { diff_file.diff_lines }

  before_all do
    create_file_in_repo(project, 'master', 'master', 'syntax.rb',
      <<~EOF
      class Hello
        def foo
        end
      end
      EOF
    )

    update_file_in_repo(project, 'master', 'master', 'syntax.rb',
      <<~EOF
      class Hello
        def bar
        end
      end
      EOF
    )
  end

  describe '#highlight' do
    subject { syntax_highlighter.highlight(diff_line) }

    context 'when diff_line unchanged' do
      let(:diff_line) { diff_lines[0] }

      it { is_expected.to eq %Q{ <span id="LC1" class="line" lang="ruby"><span class="k">class</span> <span class="nc">Hello</span></span>\n} }
    end

    context 'when diff_line is removed' do
      let(:diff_line) { diff_lines[1] }

      it { is_expected.to eq %Q{-<span id="LC2" class="line" lang="ruby">  <span class="k">def</span> <span class="nf">foo</span></span>\n} }
    end

    context 'when diff_line is added' do
      let(:diff_line) { diff_lines[2] }

      it { is_expected.to eq %Q{+<span id="LC2" class="line" lang="ruby">  <span class="k">def</span> <span class="nf">bar</span></span>\n} }
    end
  end
end
