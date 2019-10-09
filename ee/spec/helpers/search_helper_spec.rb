# frozen_string_literal: true

require 'spec_helper'

describe SearchHelper do
  describe '#search_filter_input_options' do
    let(:options) { helper.search_filter_input_options(:issues) }

    context 'with multiple issue assignees feature' do
      before do
        stub_licensed_features(multiple_issue_assignees: true)
      end

      it 'allows multiple assignees in project context' do
        @project = create :project

        expect(options[:data][:'multiple-assignees']).to eq('true')
      end

      it 'allows multiple assignees in group context' do
        @group = create :group

        expect(options[:data][:'multiple-assignees']).to eq('true')
      end

      it 'allows multiple assignees in dashboard context' do
        expect(options[:data][:'multiple-assignees']).to eq('true')
      end
    end

    context 'without multiple issue assignees feature' do
      before do
        stub_licensed_features(multiple_issue_assignees: false)
      end

      it 'does not allow multiple assignees in project context' do
        @project = create :project

        expect(options[:data][:'multiple-assignees']).to be(nil)
      end

      it 'does not allow multiple assignees in group context' do
        @group = create :group

        expect(options[:data][:'multiple-assignees']).to be(nil)
      end

      it 'allows multiple assignees in dashboard context' do
        expect(options[:data][:'multiple-assignees']).to eq('true')
      end
    end
  end

  describe '#parse_search_result with elastic enabled', :elastic do
    let(:user) { create(:user) }

    before do
      allow(self).to receive(:current_user).and_return(user)
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    it "returns parsed result" do
      project = create :project, :repository

      project.repository.index_commits_and_blobs
      Gitlab::Elastic::Helper.refresh_index

      result = project.repository.search(
        'def popen',
        type: :blob,
        options: { highlight: true }
      )[:blobs][:results][0]

      parsed_result = helper.parse_search_result(result)

      expect(parsed_result.ref). to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
      expect(parsed_result.filename).to eq('files/ruby/popen.rb')
      expect(parsed_result.startline).to eq(2)
      expect(parsed_result.data).to include("Popen")
    end
  end

  describe '#blob_projects', :elastic do
    let(:user) { create(:user) }

    before do
      allow(self).to receive(:current_user).and_return(user)
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    def es_blob_search
      Repository.search(
        'def popen',
        type: :blob,
        options: { highlight: true }
      )[:blobs][:results]
    end

    it 'returns all projects in the result page without causing an N+1' do
      control_count = ActiveRecord::QueryRecorder.new { blob_projects(es_blob_search) }.count

      projects = create_list :project, 3, :repository, :public
      projects.each { |project| project.repository.index_commits_and_blobs }

      Gitlab::Elastic::Helper.refresh_index

      # So we can access it outside the following block
      result_projects = nil

      expect { result_projects = blob_projects(es_blob_search) }.not_to exceed_query_limit(control_count)
      expect(result_projects).to match_array(projects)
    end
  end

  describe '#search_entries_info_template' do
    let(:com_value) { true }
    let(:flag_enabled) { true }
    let(:elasticsearch_enabled) { true }
    let(:show_snippets) { true }
    let(:collection) { Kaminari.paginate_array([:foo]).page(1).per(10) }
    let(:user) { create(:user) }
    let(:message) { "Showing %{count} %{scope} for \"%{term}\"" }
    let(:new_message) { message + " in your personal and project snippets" }

    subject { search_entries_info_template(collection) }

    before do
      @show_snippets = show_snippets
      @current_user = user

      allow(Gitlab).to receive(:com?).and_return(com_value)
      stub_feature_flags(restricted_snippet_scope_search: flag_enabled)
      stub_ee_application_setting(search_using_elasticsearch: elasticsearch_enabled)
    end

    shared_examples 'returns old message' do
      it do
        expect(subject).to eq message
      end
    end

    context 'when all requirements are met' do
      it 'returns a custom message' do
        expect(subject).to eq new_message
      end
    end

    context 'when not in Gitlab.com' do
      let(:com_value) { false }

      it_behaves_like 'returns old message'
    end

    context 'when flag restricted_snippet_scope_search is not enabled' do
      let(:flag_enabled) { false }

      it_behaves_like 'returns old message'
    end

    context 'when elastic search is not enabled' do
      let(:elasticsearch_enabled) { false }

      it_behaves_like 'returns old message'
    end

    context 'when no user is present' do
      let(:user) { nil }

      it_behaves_like 'returns old message'
    end

    context 'when not searching for snippets' do
      let(:show_snippets) { nil }

      it_behaves_like 'returns old message'
    end
  end
end
