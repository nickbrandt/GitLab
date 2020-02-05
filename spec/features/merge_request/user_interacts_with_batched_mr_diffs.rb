require 'spec_helper'

describe 'User interacts with batched MR diffs', :js do
  include MergeRequestDiffHelpers
	include RepoHelpers
	
	stub_feature_flags(single_mr_diff_view: true, diffs_batch_load: true)

  let(:project) { create(:project, :repository) }
  let(:merge_request) do
    create(:merge_request_with_diffs, source_project: project, target_project: project, source_branch: 'merge-test')
  end
  let(:user) { create(:user) }

  before do
    project.add_maintainer(user)
    sign_in(user)

		visit(diffs_project_merge_request_path(project, merge_request))
  end
  
  describe 'batched diffs load' do
    it 'should have the correct number of files in the UI' do
      # batch set to 1 or 2 to force at least 2 pages of batch diffs

      # wait for JS requests to settle

			# confirm that the UI has all of the files
			
			binding.pry
    end

    it 'should assign discussions to diff files across multiple batch pages' do
      # batch set to 1 or 2 to force at least 2 pages of batch diffs

      # wait for JS requests to settle

      # Add discussions to file in batch page 1
      # Add disucssions to file in batch page 2+

      # Wait for JS requests to settle

      # Reload same page with empty cache

      # Wait for JS to settle

      # Confirm discussions are applied to appropriate files (should be contained in multiple diff pages)
    end

    context 'and user visits a URL with a link directly to to a discussion' do
      # Add discussions to file in batch page 1
      # Add disucssions to file in batch page 2+
      
      context 'which is in the first batched page of diffs' do
        it 'should scroll to the correct discussion' do
          # batch set to 1 or 2 to force at least 2 pages of batch diffs

          # wait for JS requests to settle (only the first batch load? Do we have this level of control?)

          # Confirm scrolled to correct UI element
        end
      end

      context 'which is in at least page 2 of the batched pages of diffs' do
        it 'should scroll to the correct discussion' do
          # batch set to 1 or 2 to force at least 2 pages of batch diffs

          # wait for JS requests to settle

          # Confirm scrolled to correct UI element
        end
      end
    end
  end
end