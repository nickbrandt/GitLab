# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Checks::PushSingleFileCheck do
  let(:snippet) { create(:snippet, :repository) }
  let(:changes) { { oldrev: oldrev, newrev: newrev, ref: ref } }
  let(:timeout) { Gitlab::GitAccess::INTERNAL_TIMEOUT }
  let(:logger) { Gitlab::Checks::TimedLogger.new(timeout: timeout) }

  subject { described_class.new(changes, repository: snippet.repository, logger: logger) }

  describe '#validate!' do
    using RSpec::Parameterized::TableSyntax

    where(:old, :new, :valid) do
      'single-file' | 'edit-file'            | true
      'single-file' | 'multiple-files'       | false
      'single-file' | 'no-files'             | false
      'edit-file'   | 'rename-and-edit-file' | true
    end

    with_them do
      let(:oldrev) { TestEnv::BRANCH_SHA["snippet/#{old}"] }
      let(:newrev) { TestEnv::BRANCH_SHA["snippet/#{new}"] }
      let(:ref) { "refs/heads/snippet/#{new}" }

      before do
        allow(snippet.repository).to receive(:new_commits).and_return(
          snippet.repository.commits_between(oldrev, newrev)
        )
      end

      it "verifies" do
        if valid
          expect { subject.validate! }.not_to raise_error
        else
          expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError)
        end
      end
    end
  end
end
