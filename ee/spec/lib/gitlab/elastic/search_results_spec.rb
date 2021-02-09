# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Elastic::SearchResults, :elastic, :sidekiq_might_not_need_inline do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  let(:user) { create(:user) }
  let(:project_1) { create(:project, :public, :repository, :wiki_repo) }
  let(:project_2) { create(:project, :public, :repository, :wiki_repo) }
  let(:limit_project_ids) { [project_1.id] }

  describe '#highlight_map' do
    using RSpec::Parameterized::TableSyntax

    let(:results) { described_class.new(user, 'hello world', limit_project_ids) }

    where(:scope, :results_method, :expected) do
      'projects'       | :projects       | { 1 => 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }
      'milestones'     | :milestones     | { 1 => 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }
      'notes'          | :notes          | { 1 => 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }
      'issues'         | :issues         | { 1 => 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }
      'merge_requests' | :merge_requests | { 1 => 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }
      'blobs'          | nil             | nil
      'wiki_blobs'     | nil             | nil
      'commits'        | nil             | nil
      'users'          | nil             | nil
      'unknown'        | nil             | nil
    end

    with_them do
      it 'returns the expected highlight map' do
        expect(results).to receive(results_method).and_return([{ _source: { id: 1 }, highlight: 'test <span class="gl-text-gray-900 gl-font-weight-bold">highlight</span>' }]) if results_method
        expect(results.highlight_map(scope)).to eq(expected)
      end
    end
  end

  describe '#formatted_count' do
    using RSpec::Parameterized::TableSyntax

    let(:results) { described_class.new(user, 'hello world', limit_project_ids) }

    where(:scope, :count_method, :expected) do
      'projects'       | :projects_count       | '1234'
      'notes'          | :notes_count          | '1234'
      'blobs'          | :blobs_count          | '1234'
      'wiki_blobs'     | :wiki_blobs_count     | '1234'
      'commits'        | :commits_count        | '1234'
      'issues'         | :issues_count         | '1234'
      'merge_requests' | :merge_requests_count | '1234'
      'milestones'     | :milestones_count     | '1234'
      'unknown'        | nil                   | nil
    end

    with_them do
      it 'returns the expected formatted count' do
        expect(results).to receive(count_method).and_return(1234) if count_method
        expect(results.formatted_count(scope)).to eq(expected)
      end
    end
  end

  shared_examples_for 'a paginated object' do |object_type|
    let(:results) { described_class.new(user, 'hello world', limit_project_ids) }

    it 'does not explode when given a page as a string' do
      expect { results.objects(object_type, page: "2") }.not_to raise_error
    end

    it 'paginates' do
      objects = results.objects(object_type, page: 2)
      expect(objects).to respond_to(:total_count, :limit, :offset)
      expect(objects.offset_value).to eq(20)
    end

    it 'uses the per_page value if passed' do
      objects = results.objects(object_type, page: 5, per_page: 1)
      expect(objects.offset_value).to eq(4)
    end
  end

  describe 'parse_search_result' do
    let(:project) { double(:project) }
    let(:content) { "foo\nbar\nbaz\n" }
    let(:path) { 'path/file.ext' }
    let(:blob) do
      {
        'blob' => {
          'commit_sha' => 'sha',
          'content' => content,
          'path' => path
        }
      }
    end

    it 'returns an unhighlighted blob when no highlight data is present' do
      parsed = described_class.parse_search_result({ '_source' => blob }, project)

      expect(parsed).to be_kind_of(::Gitlab::Search::FoundBlob)
      expect(parsed).to have_attributes(
        startline: 1,
        highlight_line: nil,
        project: project,
        data: "foo\n"
      )
    end

    it 'parses the blob with highlighting' do
      result = {
        '_source' => blob,
        'highlight' => {
          'blob.content' => ["foo\n#{::Elastic::Latest::GitClassProxy::HIGHLIGHT_START_TAG}bar#{::Elastic::Latest::GitClassProxy::HIGHLIGHT_END_TAG}\nbaz\n"]
        }
      }

      parsed = described_class.parse_search_result(result, project)

      expect(parsed).to be_kind_of(::Gitlab::Search::FoundBlob)
      expect(parsed).to have_attributes(
        id: nil,
        path: 'path/file.ext',
        basename: 'path/file',
        ref: 'sha',
        startline: 2,
        highlight_line: 2,
        project: project,
        data: "bar\n"
      )
    end

    context 'when the highlighting finds the same terms multiple times' do
      let(:content) do
        <<~END
        bar
        bar
        foo
        bar # this is the highlighted bar
        baz
        boo
        bar
        END
      end

      it 'does not mistake a line that happens to include the same term that was highlighted on a later line' do
        highlighted_content = <<~END
        bar
        bar
        foo
        #{::Elastic::Latest::GitClassProxy::HIGHLIGHT_START_TAG}bar#{::Elastic::Latest::GitClassProxy::HIGHLIGHT_END_TAG} # this is the highlighted bar
        baz
        boo
        bar
        END

        result = {
          '_source' => blob,
          'highlight' => {
            'blob.content' => [highlighted_content]
          }
        }

        parsed = described_class.parse_search_result(result, project)

        expected_data = <<~END
        bar
        foo
        bar # this is the highlighted bar
        baz
        boo
        END

        expect(parsed).to be_kind_of(::Gitlab::Search::FoundBlob)
        expect(parsed).to have_attributes(
          id: nil,
          path: 'path/file.ext',
          basename: 'path/file',
          ref: 'sha',
          startline: 2,
          highlight_line: 4,
          project: project,
          data: expected_data
        )
      end
    end

    context 'file path in the blob contains potential backtracking regex attack pattern' do
      let(:path) { '/group/project/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab.(a+)+$' }

      it 'still parses the basename from the path with reasonable amount of time' do
        Timeout.timeout(3.seconds) do
          parsed = described_class.parse_search_result({ '_source' => blob }, project)

          expect(parsed).to be_kind_of(::Gitlab::Search::FoundBlob)
          expect(parsed).to have_attributes(
            basename: '/group/project/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab'
          )
        end
      end
    end
  end

  describe 'issues' do
    let(:scope) { 'issues' }
    let!(:issue_1) { create(:issue, project: project_1, title: 'Hello world, here I am!', description: '20200623170000, see details in issue 287661', iid: 1) }
    let!(:issue_2) { create(:issue, project: project_1, title: 'Issue Two', description: 'Hello world, here I am!', iid: 2) }
    let!(:issue_3) { create(:issue, project: project_2, title: 'Issue Three', iid: 2) }

    before do
      ensure_elasticsearch_index!
    end

    it_behaves_like 'a paginated object', 'issues'

    it 'lists found issues' do
      results = described_class.new(user, 'hello world', limit_project_ids)
      issues = results.objects('issues')

      expect(issues).to contain_exactly(issue_1, issue_2)
      expect(results.issues_count).to eq 2
    end

    it 'returns empty list when issues are not found' do
      results = described_class.new(user, 'security', limit_project_ids)

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end

    it 'lists issue when search by a valid iid' do
      results = described_class.new(user, '#2', limit_project_ids, public_and_internal_projects: false)
      issues = results.objects('issues')

      expect(issues).to contain_exactly(issue_2)
      expect(results.issues_count).to eq 1
    end

    it 'can also find an issue by iid without the prefixed #' do
      results = described_class.new(user, '2', limit_project_ids, public_and_internal_projects: false)
      issues = results.objects('issues')

      expect(issues).to contain_exactly(issue_2)
      expect(results.issues_count).to eq 1
    end

    it 'finds the issue with an out of integer range number in its description without exception' do
      results = described_class.new(user, '20200623170000', limit_project_ids, public_and_internal_projects: false)
      issues = results.objects('issues')

      expect(issues).to contain_exactly(issue_1)
      expect(results.issues_count).to eq 1
    end

    it 'returns empty list when search by invalid iid' do
      results = described_class.new(user, '#222', limit_project_ids)

      expect(results.objects('issues')).to be_empty
      expect(results.issues_count).to eq 0
    end

    it 'handles plural words through algorithmic stemming', :aggregate_failures do
      issue1 = create(:issue, project: project_1, title: 'remove :title attribute from submit buttons to prevent un-styled tooltips')
      issue2 = create(:issue, project: project_1, title: 'smarter submit behavior for buttons groups')

      ensure_elasticsearch_index!

      results = described_class.new(user, 'button', limit_project_ids)

      expect(results.objects('issues')).to contain_exactly(issue1, issue2)
      expect(results.issues_count).to eq 2
    end

    it 'executes count only queries' do
      results = described_class.new(user, 'hello world', limit_project_ids)
      expect(results).to receive(:issues).with(count_only: true).and_call_original

      count = results.issues_count

      expect(count).to eq(2)
    end

    context 'filtering' do
      let!(:project) { create(:project, :public) }
      let!(:closed_result) { create(:issue, :closed, project: project, title: 'foo closed') }
      let!(:opened_result) { create(:issue, :opened, project: project, title: 'foo opened') }
      let!(:confidential_result) { create(:issue, :confidential, project: project, title: 'foo confidential') }

      let(:results) { described_class.new(user, 'foo', [project.id], filters: filters) }

      before do
        project.add_developer(user)

        ensure_elasticsearch_index!
      end

      include_examples 'search results filtered by state'
      include_examples 'search results filtered by confidential'
    end

    context 'ordering' do
      let!(:project) { create(:project, :public) }

      let!(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:issue, project: project, title: 'sorted very old', created_at: 1.year.ago) }
      let(:results_created) { described_class.new(user, 'sorted', [project.id], sort: sort) }

      let!(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:issue, project: project, title: 'updated very old', updated_at: 1.year.ago) }
      let(:results_updated) { described_class.new(user, 'updated', [project.id], sort: sort) }

      before do
        ensure_elasticsearch_index!
      end

      include_examples 'search results sorted'
    end
  end

  describe 'notes' do
    let(:issue) { create(:issue, project: project_1, title: 'Hello') }

    before do
      @note_1 = create(
        :note,
        noteable: issue,
        project: project_1,
        note: 'foo bar'
      )
      @note_2 = create(
        :note_on_issue,
        noteable: issue,
        project: project_1,
        note: 'foo baz'
      )
      @note_3 = create(
        :note_on_issue,
        noteable: issue,
        project: project_1,
        note: 'bar baz'
      )

      ensure_elasticsearch_index!
    end

    it_behaves_like 'a paginated object', 'notes'

    it 'lists found notes' do
      results = described_class.new(user, 'foo', limit_project_ids)
      notes = results.objects('notes')

      expect(notes).to include @note_1
      expect(notes).to include @note_2
      expect(notes).not_to include @note_3
      expect(results.notes_count).to eq 2
    end

    it 'returns empty list when notes are not found' do
      results = described_class.new(user, 'security', limit_project_ids)

      expect(results.objects('notes')).to be_empty
      expect(results.notes_count).to eq 0
    end
  end

  describe 'confidential issues' do
    let(:project_3) { create(:project, :public) }
    let(:project_4) { create(:project, :public) }
    let(:limit_project_ids) { [project_1.id, project_2.id, project_3.id] }
    let(:author) { create(:user) }
    let(:assignee) { create(:user) }
    let(:non_member) { create(:user) }
    let(:member) { create(:user) }
    let(:admin) { create(:admin) }

    before do
      @issue = create(:issue, project: project_1, title: 'Issue 1', iid: 1)
      @security_issue_1 = create(:issue, :confidential, project: project_1, title: 'Security issue 1', author: author, iid: 2)
      @security_issue_2 = create(:issue, :confidential, title: 'Security issue 2', project: project_1, assignees: [assignee], iid: 3)
      @security_issue_3 = create(:issue, :confidential, project: project_2, title: 'Security issue 3', author: author, iid: 1)
      @security_issue_4 = create(:issue, :confidential, project: project_3, title: 'Security issue 4', assignees: [assignee], iid: 1)
      @security_issue_5 = create(:issue, :confidential, project: project_4, title: 'Security issue 5', iid: 1)

      ensure_elasticsearch_index!
    end

    context 'search by term' do
      let(:query) { 'issue' }

      it 'does not list confidential issues for guests' do
        results = described_class.new(nil, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'does not list confidential issues for non project members' do
        results = described_class.new(non_member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'lists confidential issues for author' do
        results = described_class.new(author, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'lists confidential issues for assignee' do
        results = described_class.new(assignee, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      it 'lists confidential issues for project members' do
        project_1.add_developer(member)
        project_2.add_developer(member)

        results = described_class.new(member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).to include @security_issue_1
        expect(issues).to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 4
      end

      context 'for admin users' do
        context 'when admin mode enabled', :enable_admin_mode do
          it 'lists all issues' do
            results = described_class.new(admin, query, limit_project_ids)
            issues = results.objects('issues')

            expect(issues).to include @issue
            expect(issues).to include @security_issue_1
            expect(issues).to include @security_issue_2
            expect(issues).to include @security_issue_3
            expect(issues).to include @security_issue_4
            expect(issues).to include @security_issue_5
            expect(results.issues_count).to eq 6
          end
        end

        context 'when admin mode disabled' do
          it 'does not list confidential issues' do
            results = described_class.new(admin, query, limit_project_ids)
            issues = results.objects('issues')

            expect(issues).to include @issue
            expect(issues).not_to include @security_issue_1
            expect(issues).not_to include @security_issue_2
            expect(issues).not_to include @security_issue_3
            expect(issues).not_to include @security_issue_4
            expect(issues).not_to include @security_issue_5
            expect(results.issues_count).to eq 1
          end
        end
      end
    end

    context 'search by iid' do
      let(:query) { '#1' }

      it 'does not list confidential issues for guests' do
        results = described_class.new(nil, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'does not list confidential issues for non project members' do
        results = described_class.new(non_member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 1
      end

      it 'lists confidential issues for author' do
        results = described_class.new(author, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).not_to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 2
      end

      it 'lists confidential issues for assignee' do
        results = described_class.new(assignee, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).not_to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 2
      end

      it 'lists confidential issues for project members' do
        project_2.add_developer(member)
        project_3.add_developer(member)

        results = described_class.new(member, query, limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include @issue
        expect(issues).not_to include @security_issue_1
        expect(issues).not_to include @security_issue_2
        expect(issues).to include @security_issue_3
        expect(issues).to include @security_issue_4
        expect(issues).not_to include @security_issue_5
        expect(results.issues_count).to eq 3
      end

      context 'for admin users' do
        context 'when admin mode enabled', :enable_admin_mode do
          it 'lists all issues' do
            results = described_class.new(admin, query, limit_project_ids)
            issues = results.objects('issues')

            expect(issues).to include @issue
            expect(issues).not_to include @security_issue_1
            expect(issues).not_to include @security_issue_2
            expect(issues).to include @security_issue_3
            expect(issues).to include @security_issue_4
            expect(issues).to include @security_issue_5
            expect(results.issues_count).to eq 4
          end
        end

        context 'when admin mode disabled' do
          it 'does not list confidential issues' do
            results = described_class.new(admin, query, limit_project_ids)
            issues = results.objects('issues')

            expect(issues).to include @issue
            expect(issues).not_to include @security_issue_1
            expect(issues).not_to include @security_issue_2
            expect(issues).not_to include @security_issue_3
            expect(issues).not_to include @security_issue_4
            expect(issues).not_to include @security_issue_5
            expect(results.issues_count).to eq 1
          end
        end
      end
    end
  end

  describe 'merge requests' do
    let(:scope) { 'merge_requests' }

    before do
      @merge_request_1 = create(
        :merge_request,
        source_project: project_1,
        target_project: project_1,
        title: 'Hello world, here I am!',
        description: '20200623170000, see details in issue 287661',
        iid: 1
      )
      @merge_request_2 = create(
        :merge_request,
        :conflict,
        source_project: project_1,
        target_project: project_1,
        title: 'Merge Request Two',
        description: 'Hello world, here I am!',
        iid: 2
      )
      @merge_request_3 = create(
        :merge_request,
        source_project: project_2,
        target_project: project_2,
        title: 'Merge Request Three',
        iid: 2
      )

      ensure_elasticsearch_index!
    end

    it_behaves_like 'a paginated object', 'merge_requests'

    it 'lists found merge requests' do
      results = described_class.new(user, 'hello world', limit_project_ids, public_and_internal_projects: false)
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to contain_exactly(@merge_request_1, @merge_request_2)
      expect(results.merge_requests_count).to eq 2
    end

    it 'returns empty list when merge requests are not found' do
      results = described_class.new(user, 'security', limit_project_ids)

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end

    it 'lists merge request when search by a valid iid' do
      results = described_class.new(user, '!2', limit_project_ids, public_and_internal_projects: false)
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to contain_exactly(@merge_request_2)
      expect(results.merge_requests_count).to eq 1
    end

    it 'can also find an issue by iid without the prefixed !' do
      results = described_class.new(user, '2', limit_project_ids, public_and_internal_projects: false)
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to contain_exactly(@merge_request_2)
      expect(results.merge_requests_count).to eq 1
    end

    it 'finds the MR with an out of integer range number in its description without exception' do
      results = described_class.new(user, '20200623170000', limit_project_ids, public_and_internal_projects: false)
      merge_requests = results.objects('merge_requests')

      expect(merge_requests).to contain_exactly(@merge_request_1)
      expect(results.merge_requests_count).to eq 1
    end

    it 'returns empty list when search by invalid iid' do
      results = described_class.new(user, '#222', limit_project_ids)

      expect(results.objects('merge_requests')).to be_empty
      expect(results.merge_requests_count).to eq 0
    end

    context 'filtering' do
      let!(:project) { create(:project, :public) }
      let!(:opened_result) { create(:merge_request, :opened, source_project: project, title: 'foo opened') }
      let!(:closed_result) { create(:merge_request, :closed, source_project: project, title: 'foo closed') }

      let(:results) { described_class.new(user, 'foo', [project.id], filters: filters) }

      include_examples 'search results filtered by state' do
        before do
          ensure_elasticsearch_index!
        end
      end
    end

    context 'ordering' do
      let!(:project) { create(:project, :public) }

      let!(:old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'old-1', title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:merge_request, :opened, source_project: project, source_branch: 'new-1', title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'very-old-1', title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-old-1', title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-new-1', title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-very-old-1', title: 'updated very old', updated_at: 1.year.ago) }

      before do
        ensure_elasticsearch_index!
      end

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(user, 'sorted', [project.id], sort: sort) }
        let(:results_updated) { described_class.new(user, 'updated', [project.id], sort: sort) }
      end
    end
  end

  describe 'project scoping' do
    it "returns items for project" do
      project = create :project, :repository, name: "term"
      project.add_developer(user)

      # Create issue
      create :issue, title: 'bla-bla term', project: project
      create :issue, description: 'bla-bla term', project: project
      create :issue, project: project
      # The issue I have no access to
      create :issue, title: 'bla-bla term'

      # Create Merge Request
      create :merge_request, title: 'bla-bla term', source_project: project
      create :merge_request, description: 'term in description', source_project: project, target_branch: "feature2"
      create :merge_request, source_project: project, target_branch: "feature3"
      # The merge request you have no access to
      create :merge_request, title: 'also with term'

      create :milestone, title: 'bla-bla term', project: project
      create :milestone, description: 'bla-bla term', project: project
      create :milestone, project: project
      # The Milestone you have no access to
      create :milestone, title: 'bla-bla term'

      ensure_elasticsearch_index!

      result = described_class.new(user, 'term', [project.id])

      expect(result.issues_count).to eq(2)
      expect(result.merge_requests_count).to eq(2)
      expect(result.milestones_count).to eq(2)
      expect(result.projects_count).to eq(1)
    end
  end

  describe 'blobs' do
    before do
      project_1.repository.index_commits_and_blobs

      ensure_elasticsearch_index!
    end

    def search_for(term)
      described_class.new(user, term, [project_1.id]).objects('blobs').map(&:path)
    end

    it_behaves_like 'a paginated object', 'blobs'

    it 'finds blobs' do
      results = described_class.new(user, 'def', limit_project_ids)
      blobs = results.objects('blobs')

      expect(blobs.first.data).to include('def')
      expect(results.blobs_count).to eq 5
    end

    it 'finds blobs by prefix search' do
      results = described_class.new(user, 'defau*', limit_project_ids)
      blobs = results.objects('blobs')

      expect(blobs.first.data).to match(/default/i)
      expect(results.blobs_count).to eq 3
    end

    it 'finds blobs from public projects only' do
      project_2 = create :project, :repository, :private
      project_2.repository.index_commits_and_blobs
      project_2.add_reporter(user)
      ensure_elasticsearch_index!

      results = described_class.new(user, 'def', [project_1.id])
      expect(results.blobs_count).to eq 5
      result_project_ids = results.objects('blobs').map(&:project_id)
      expect(result_project_ids.uniq).to eq([project_1.id])

      results = described_class.new(user, 'def', [project_1.id, project_2.id])

      expect(results.blobs_count).to eq 10
    end

    it 'returns zero when blobs are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.blobs_count).to eq 0
    end

    context 'Searches CamelCased methods' do
      before do
        project_1.repository.create_file(
          user,
          'test.txt',
          ' function writeStringToFile(){} ',
          message: 'added test file',
          branch_name: 'master')

        project_1.repository.index_commits_and_blobs

        ensure_elasticsearch_index!
      end

      it 'find by first word' do
        expect(search_for('write')).to include('test.txt')
      end

      # Re-enable after fixing https://gitlab.com/gitlab-org/gitlab/-/issues/10693#note_349683299
      xit 'find by first two words' do
        expect(search_for('writeString')).to include('test.txt')
      end

      it 'find by last two words' do
        expect(search_for('ToFile')).to include('test.txt')
      end

      it 'find by exact match' do
        expect(search_for('writeStringToFile')).to include('test.txt')
      end

      it 'find by prefix search' do
        expect(search_for('writeStr*')).to include('test.txt')
      end
    end

    context 'Searches special characters' do
      let(:file_content) do
        <<~FILE
          us

          some other stuff

          dots.also.need.testing

          and;colons:too$
          wow
          yeah!

          Foo.bar(x)

          include "bikes-3.4"
          /a/longer/file-path/absolute_with_specials.txt
          another/file-path/relative-with-specials.txt
          /file-path/components-within-slashes/
          another/file-path/differeñt-lønguage.txt

          us-east-2
          bye

          MyJavaClass::javaLangStaticMethodCall
          $my_perl_object->perlMethodCall
          LanguageWithSingleColon:someSingleColonMethodCall
          WouldHappenInManyLanguages,tokenAfterCommaWithNoSpace
          ParenthesesBetweenTokens)tokenAfterParentheses
          a.b.c=missing_token_around_equals

          def self.ruby_method_name(ruby_method_arg)
          RubyClassInvoking.ruby_method_call(with_arg)

          def self.ruby_method_123(ruby_another_method_arg)
          RubyClassInvoking.ruby_call_method_123(with_arg)

        FILE
      end

      let(:file_name) { 'elastic_specialchars_test.md' }

      before do
        project_1.repository.create_file(user, file_name, file_content, message: 'Some commit message', branch_name: 'master')
        project_1.repository.index_commits_and_blobs
        ensure_elasticsearch_index!
      end

      it 'finds files with dashes' do
        expect(search_for('"us-east-2"')).to include(file_name)
        expect(search_for('bikes-3.4')).to include(file_name)
      end

      it 'finds files with dots' do
        expect(search_for('"dots.also.need.testing"')).to include(file_name)
        expect(search_for('dots')).to include(file_name)
        expect(search_for('need')).to include(file_name)
        expect(search_for('dots.need')).not_to include(file_name)
      end

      it 'finds files with other special chars' do
        expect(search_for('"and;colons:too$"')).to include(file_name)
        expect(search_for('bar\(x\)')).to include(file_name)
      end

      it 'finds absolute file paths with slashes and other special chars' do
        expect(search_for('"absolute_with_specials.txt"')).to include(file_name)
      end

      it 'finds relative file paths with slashes and other special chars' do
        expect(search_for('"relative-with-specials.txt"')).to include(file_name)
      end

      it 'finds file path components within slashes for directories' do
        expect(search_for('"components-within-slashes"')).to include(file_name)
      end

      it 'finds file paths for various languages' do
        expect(search_for('"differeñt-lønguage.txt"')).to include(file_name)
      end

      it 'finds java style static method call after ::' do
        expect(search_for('javaLangStaticMethodCall')).to include(file_name)
      end

      it 'finds perl object method call' do
        expect(search_for('perlMethodCall')).to include(file_name)
      end

      it 'finds tokens after a colon' do
        expect(search_for('someSingleColonMethodCall')).to include(file_name)
      end

      it 'finds tokens after a comma with no space' do
        expect(search_for('tokenAfterCommaWithNoSpace')).to include(file_name)
      end

      it 'finds a token directly after parentheses' do
        expect(search_for('tokenAfterParentheses')).to include(file_name)
      end

      it 'finds a token after = without a space' do
        expect(search_for('missing_token_around_equals')).to include(file_name)
      end

      it 'finds a ruby method name even if preceded with dot' do
        expect(search_for('ruby_method_name')).to include(file_name)
      end

      it 'finds a ruby method name with numbers' do
        expect(search_for('ruby_method_123')).to include(file_name)
      end

      it 'finds a ruby method call even if preceded with dot' do
        expect(search_for('ruby_method_call')).to include(file_name)
      end

      it 'finds a ruby method call with numbers' do
        expect(search_for('ruby_call_method_123')).to include(file_name)
      end
    end
  end

  describe 'wikis' do
    let(:results) { described_class.new(user, 'term', limit_project_ids) }

    subject(:wiki_blobs) { results.objects('wiki_blobs') }

    before do
      if project_1.wiki_enabled?
        project_1.wiki.create_page('index_page', 'term')
        project_1.wiki.index_wiki_blobs
      end

      ensure_elasticsearch_index!
    end

    it_behaves_like 'a paginated object', 'wiki_blobs'

    it 'finds wiki blobs' do
      blobs = results.objects('wiki_blobs')

      expect(blobs.first.data).to include('term')
      expect(results.wiki_blobs_count).to eq 1
    end

    it 'finds wiki blobs for guest' do
      project_1.add_guest(user)
      blobs = results.objects('wiki_blobs')

      expect(blobs.first.data).to include('term')
      expect(results.wiki_blobs_count).to eq 1
    end

    it 'finds wiki blobs from public projects only' do
      project_2 = create :project, :repository, :private, :wiki_repo
      project_2.wiki.create_page('index_page', 'term')
      project_2.wiki.index_wiki_blobs
      project_2.add_guest(user)
      ensure_elasticsearch_index!

      expect(results.wiki_blobs_count).to eq 1

      results = described_class.new(user, 'term', [project_1.id, project_2.id])
      expect(results.wiki_blobs_count).to eq 2
    end

    it 'returns zero when wiki blobs are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.wiki_blobs_count).to eq 0
    end

    context 'when wiki is disabled' do
      let(:project_1) { create(:project, :public, :repository, :wiki_disabled) }

      context 'search by member' do
        let(:limit_project_ids) { [project_1.id] }

        it { is_expected.to be_empty }
      end

      context 'search by non-member' do
        let(:limit_project_ids) { [] }

        it { is_expected.to be_empty }
      end
    end

    context 'when wiki is internal' do
      let(:project_1) { create(:project, :public, :repository, :wiki_private, :wiki_repo) }

      context 'search by member' do
        let(:limit_project_ids) { [project_1.id] }

        before do
          project_1.add_guest(user)
        end

        it { is_expected.not_to be_empty }
      end

      context 'search by non-member' do
        let(:limit_project_ids) { [] }

        it { is_expected.to be_empty }
      end
    end
  end

  describe 'commits' do
    before do
      project_1.repository.index_commits_and_blobs
      ensure_elasticsearch_index!
    end

    it_behaves_like 'a paginated object', 'commits'

    it 'finds commits' do
      results = described_class.new(user, 'add', limit_project_ids)
      commits = results.objects('commits')

      expect(commits.first.message.downcase).to include("add")
      expect(results.commits_count).to eq 21
    end

    it 'finds commits from public projects only' do
      project_2 = create :project, :private, :repository
      project_2.repository.index_commits_and_blobs
      project_2.add_reporter(user)
      ensure_elasticsearch_index!

      results = described_class.new(user, 'add', [project_1.id])
      expect(results.commits_count).to eq 21

      results = described_class.new(user, 'add', [project_1.id, project_2.id])
      expect(results.commits_count).to eq 42
    end

    it 'returns zero when commits are not found' do
      results = described_class.new(user, 'asdfg', limit_project_ids)

      expect(results.commits_count).to eq 0
    end
  end

  describe 'visibility levels' do
    let(:internal_project) { create(:project, :internal, :repository, :wiki_repo, description: "Internal project") }
    let(:private_project1) { create(:project, :private, :repository, :wiki_repo, description: "Private project") }
    let(:private_project2) { create(:project, :private, :repository, :wiki_repo, description: "Private project where I'm a member") }
    let(:public_project) { create(:project, :public, :repository, :wiki_repo, description: "Public project") }
    let(:limit_project_ids) { [private_project2.id] }

    before do
      private_project2.project_members.create(user: user, access_level: ProjectMember::DEVELOPER)
    end

    context 'issues' do
      it 'finds right set of issues' do
        issue_1 = create :issue, project: internal_project, title: "Internal project"
        create :issue, project: private_project1, title: "Private project"
        issue_3 = create :issue, project: private_project2, title: "Private project where I'm a member"
        issue_4 = create :issue, project: public_project, title: "Public project"

        ensure_elasticsearch_index!

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        issues = results.objects('issues')

        expect(issues).to include issue_1
        expect(issues).to include issue_3
        expect(issues).to include issue_4
        expect(results.issues_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        issues = results.objects('issues')

        expect(issues).to include issue_4
        expect(results.issues_count).to eq 1
      end
    end

    context 'milestones' do
      let!(:milestone_1) { create(:milestone, project: internal_project, title: "Internal project") }
      let!(:milestone_2) { create(:milestone, project: private_project1, title: "Private project") }
      let!(:milestone_3) { create(:milestone, project: private_project2, title: "Private project which user is member") }
      let!(:milestone_4) { create(:milestone, project: public_project, title: "Public project") }

      before do
        ensure_elasticsearch_index!
      end

      it_behaves_like 'a paginated object', 'milestones'

      context 'when project ids are present' do
        context 'when authenticated' do
          context 'when user and merge requests are disabled in a project' do
            it 'returns right set of milestones' do
              private_project2.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
              private_project2.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
              public_project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
              public_project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
              internal_project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
              ensure_elasticsearch_index!

              projects = user.authorized_projects
              results = described_class.new(user, 'project', projects.pluck_primary_key)
              milestones = results.objects('milestones')

              expect(milestones).to match_array([milestone_1, milestone_3])
            end
          end

          context 'when user is admin' do
            context 'when admin mode enabled', :enable_admin_mode do
              it 'returns right set of milestones' do
                user.update(admin: true)
                public_project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
                public_project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
                internal_project.project_feature.update!(issues_access_level: ProjectFeature::DISABLED)
                internal_project.project_feature.update!(merge_requests_access_level: ProjectFeature::DISABLED)
                ensure_elasticsearch_index!

                results = described_class.new(user, 'project', :any)
                milestones = results.objects('milestones')

                expect(milestones).to match_array([milestone_2, milestone_3, milestone_4])
              end
            end
          end

          context 'when user can read milestones' do
            it 'returns right set of milestones' do
              # Authenticated search
              projects = user.authorized_projects
              results = described_class.new(user, 'project', projects.pluck_primary_key)
              milestones = results.objects('milestones')

              expect(milestones).to match_array([milestone_1, milestone_3, milestone_4])
            end
          end
        end
      end

      context 'when not authenticated' do
        it 'returns right set of milestones' do
          results = described_class.new(nil, 'project', [])
          milestones = results.objects('milestones')

          expect(milestones).to include milestone_4
          expect(results.milestones_count).to eq 1
        end
      end

      context 'when project_ids is not present' do
        context 'when project_ids is :any' do
          it 'returns all milestones' do
            results = described_class.new(user, 'project', :any)

            milestones = results.objects('milestones')

            expect(results.milestones_count).to eq(4)

            expect(milestones).to include(milestone_1)
            expect(milestones).to include(milestone_2)
            expect(milestones).to include(milestone_3)
            expect(milestones).to include(milestone_4)
          end
        end

        context 'when authenticated' do
          it 'returns right set of milestones' do
            results = described_class.new(user, 'project', [])
            milestones = results.objects('milestones')

            expect(milestones).to include(milestone_1)
            expect(milestones).to include(milestone_4)
            expect(results.milestones_count).to eq(2)
          end
        end

        context 'when not authenticated' do
          it 'returns right set of milestones' do
            # Should not be returned because issues and merge requests feature are disabled
            other_public_project = create(:project, :public)
            create(:milestone, project: other_public_project, title: 'Public project milestone 1')
            other_public_project.project_feature.update!(merge_requests_access_level: ProjectFeature::PRIVATE)
            other_public_project.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
            # Should be returned because only issues is disabled
            other_public_project_1 = create(:project, :public)
            milestone_5 = create(:milestone, project: other_public_project_1, title: 'Public project milestone 2')
            other_public_project_1.project_feature.update!(issues_access_level: ProjectFeature::PRIVATE)
            ensure_elasticsearch_index!

            results = described_class.new(nil, 'project', [])
            milestones = results.objects('milestones')

            expect(milestones).to match_array([milestone_4, milestone_5])
            expect(results.milestones_count).to eq(2)
          end
        end
      end
    end

    context 'projects' do
      it_behaves_like 'a paginated object', 'projects'

      it 'finds right set of projects' do
        internal_project
        private_project1
        private_project2
        public_project

        ensure_elasticsearch_index!

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        milestones = results.objects('projects')

        expect(milestones).to include internal_project
        expect(milestones).to include private_project2
        expect(milestones).to include public_project
        expect(results.projects_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        projects = results.objects('projects')

        expect(projects).to include public_project
        expect(results.projects_count).to eq 1
      end
    end

    context 'merge requests' do
      it 'finds right set of merge requests' do
        merge_request_1 = create :merge_request, target_project: internal_project, source_project: internal_project, title: "Internal project"
        create :merge_request, target_project: private_project1, source_project: private_project1, title: "Private project"
        merge_request_3 = create :merge_request, target_project: private_project2, source_project: private_project2, title: "Private project where I'm a member"
        merge_request_4 = create :merge_request, target_project: public_project, source_project: public_project, title: "Public project"

        ensure_elasticsearch_index!

        # Authenticated search
        results = described_class.new(user, 'project', limit_project_ids)
        merge_requests = results.objects('merge_requests')

        expect(merge_requests).to include merge_request_1
        expect(merge_requests).to include merge_request_3
        expect(merge_requests).to include merge_request_4
        expect(results.merge_requests_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'project', [])
        merge_requests = results.objects('merge_requests')

        expect(merge_requests).to include merge_request_4
        expect(results.merge_requests_count).to eq 1
      end
    end

    context 'wikis' do
      before do
        [public_project, internal_project, private_project1, private_project2].each do |project|
          project.wiki.create_page('index_page', 'term')
          project.wiki.index_wiki_blobs
        end

        ensure_elasticsearch_index!
      end

      it 'finds the right set of wiki blobs' do
        # Authenticated search
        results = described_class.new(user, 'term', limit_project_ids)
        blobs = results.objects('wiki_blobs')

        expect(blobs.map(&:project)).to match_array [internal_project, private_project2, public_project]
        expect(results.wiki_blobs_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'term', [])
        blobs = results.objects('wiki_blobs')

        expect(blobs.first.project).to eq public_project
        expect(results.wiki_blobs_count).to eq 1
      end
    end

    context 'commits' do
      it 'finds right set of commits' do
        [internal_project, private_project1, private_project2, public_project].each do |project|
          project.repository.create_file(
            user,
            'test-file',
            'search test',
            message: 'search test',
            branch_name: 'master'
          )

          project.repository.index_commits_and_blobs
        end

        ensure_elasticsearch_index!

        # Authenticated search
        results = described_class.new(user, 'search', limit_project_ids)
        commits = results.objects('commits')

        expect(commits.map(&:project)).to match_array [internal_project, private_project2, public_project]
        expect(results.commits_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'search', [])
        commits = results.objects('commits')

        expect(commits.first.project).to eq public_project
        expect(results.commits_count).to eq 1
      end
    end

    context 'blobs' do
      it 'finds right set of blobs' do
        [internal_project, private_project1, private_project2, public_project].each do |project|
          project.repository.create_file(
            user,
            'test-file',
            'tesla',
            message: 'search test',
            branch_name: 'master'
          )

          project.repository.index_commits_and_blobs
        end

        ensure_elasticsearch_index!

        # Authenticated search
        results = described_class.new(user, 'tesla', limit_project_ids)
        blobs = results.objects('blobs')

        expect(blobs.map(&:project)).to match_array [internal_project, private_project2, public_project]
        expect(results.blobs_count).to eq 3

        # Unauthenticated search
        results = described_class.new(nil, 'tesla', [])
        blobs = results.objects('blobs')

        expect(blobs.first.project).to eq public_project
        expect(results.blobs_count).to eq 1
      end
    end
  end

  context 'query performance' do
    let(:results) { described_class.new(user, 'hello world', limit_project_ids) }

    include_examples 'does not hit Elasticsearch twice for objects and counts', %w[projects notes blobs wiki_blobs commits issues merge_requests milestones]
    include_examples 'does not load results for count only queries', %w[projects notes blobs wiki_blobs commits issues merge_requests milestones]
  end
end
