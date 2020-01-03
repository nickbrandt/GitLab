# frozen_string_literal: true

require 'spec_helper'

describe Elastic::IndexRecordService, :elastic do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)

    Elasticsearch::Model.client =
      Gitlab::Elastic::Client.build(Gitlab::CurrentSettings.elasticsearch_config)
  end

  describe 'Indexing, updating, and deleting records' do
    using RSpec::Parameterized::TableSyntax

    where(:type, :name, :attribute) do
      :project       | "Project"      | :name
      :issue         | "Issue"        | :title
      :note          | "Note"         | :note
      :milestone     | "Milestone"    | :title
      :merge_request | "MergeRequest" | :title
    end

    with_them do
      it 'indexes new records' do
        object = nil
        Sidekiq::Testing.disable! do
          object = create(type)
        end

        expect do
          expect(subject.execute(object, true)).to eq(true)
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'updates the index when object is changed' do
        object = nil

        Sidekiq::Testing.disable! do
          object = create(type)
          expect(subject.execute(object, true)).to eq(true)
          object.update(attribute => "new")
        end

        expect do
          expect(subject.execute(object, false)).to eq(true)
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
      end

      it 'ignores Elasticsearch::Transport::Transport::Errors::NotFound errors' do
        object = create(type)

        allow(object.__elasticsearch__).to receive(:index_document).and_raise(Elasticsearch::Transport::Transport::Errors::NotFound)

        expect(subject.execute(object, true)).to eq(true)
      end
    end
  end

  context 'with nested associations' do
    let(:project) { create :project, :repository }

    before do
      Sidekiq::Testing.disable! do
        create :issue, project: project
        create :milestone, project: project
        create :note, project: project
        create :merge_request, target_project: project, source_project: project
        create :project_snippet, project: project
      end

      # Nothing should be in the index at this point
      expect(Elasticsearch::Model.search('*').total_count).to be(0)
    end

    it 'indexes records associated with the project' do
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id).and_call_original
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, nil, nil, true).and_call_original

      Sidekiq::Testing.inline! do
        expect(subject.execute(project, true)).to eq(true)
      end
      Gitlab::Elastic::Helper.refresh_index

      # Fetch all child documents
      children = Elasticsearch::Model.search(
        size: 100,
        query: {
          has_parent: {
            parent_type: 'project',
            query: {
              term: { id: project.id }
            }
          }
        }
      )

      # The absolute value does not matter
      expect(children.total_count).to be > 40

      # Make sure all types are present
      expect(children.pluck(:_source).pluck(:type).uniq).to contain_exactly(
        'blob',
        'commit',
        'issue',
        'merge_request',
        'milestone',
        'note'
      )
    end

    it 'does not index records not associated with the project' do
      other_project = create :project

      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(other_project.id).and_call_original
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(other_project.id, nil, nil, true).and_call_original

      Sidekiq::Testing.inline! do
        expect(subject.execute(other_project, true)).to eq(true)
      end
      Gitlab::Elastic::Helper.refresh_index

      # Only the project itself should be in the index
      expect(Elasticsearch::Model.search('*').total_count).to be 1
      expect(Project.elastic_search('*').records).to contain_exactly(other_project)
    end

    context 'retry indexing record' do
      let(:failure_response) do
        {
          "_shards" => {
            "total" => 2,
            "failed" => 2,
            "successful" => 0
          },
          "_index" => "foo",
          "_type" => "_doc",
          "_id" => "project_1",
          "_version" => 1,
          "created" => false,
          "result" => ""
        }
      end

      before do
        allow(ElasticCommitIndexerWorker).to receive(:perform_async)
      end

      it 'does not retry if successful' do
        expect(project.__elasticsearch__).to receive(:index_document).once.and_call_original

        expect(subject.execute(project, true)).to eq(true)
      end

      it 'retries, and raises error if all retries fail' do
        expect(project.__elasticsearch__).to receive(:index_document)
          .exactly(described_class::IMPORT_RETRY_COUNT).times
          .and_return(failure_response)

        expect { subject.execute(project, true) }.to raise_error(described_class::ImportError)
      end

      it 'retries, and returns true if a retry is successful' do
        expect(project.__elasticsearch__).to receive(:index_document).and_wrap_original do |m, *args|
          allow(project.__elasticsearch__).to receive(:index_document).and_call_original

          m.call(*args)
        end

        expect(subject.execute(project, true)).to eq(true)
      end
    end

    context 'retry importing associations' do
      let(:issues) { Issue.all.to_a }
      let(:failure_response) do
        {
          "took" => 30,
          "errors" => true,
          "items" => [
            {
              "index" => {
                "error" => 'FAILED',
                "_index" => "test",
                "_type" => "_doc",
                "_id" => issues.first.es_id,
                "_version" => 1,
                "result" => "created",
                "_shards" => {
                  "total" => 2,
                  "successful" => 1,
                  "failed" => 0
                },
                "status" => 400
              }
            },
            {
              "index" => {
                "_index" => "test",
                "_type" => "_doc",
                "_id" => issues.last.es_id,
                "_version" => 1,
                "result" => "created",
                "_shards" => {
                  "total" => 2,
                  "successful" => 1,
                  "failed" => 0
                },
                "status" => 201
              }
            }
          ]
        }
      end

      let(:success_response) do
        {
          "took" => 30,
          "errors" => false,
          "items" => [
            {
              "index" => {
                "_index" => "test",
                "_type" => "_doc",
                "_id" => issues.first.es_id,
                "_version" => 1,
                "result" => "created",
                "_shards" => {
                  "total" => 2,
                  "successful" => 1,
                  "failed" => 0
                },
                "status" => 201
              }
            }
          ]
        }
      end

      before do
        allow(ElasticCommitIndexerWorker).to receive(:perform_async)
      end

      def expect_indexing(issue_ids, response, unstub: false)
        expect(Issue.__elasticsearch__.client).to receive(:bulk) do |args|
          actual_ids = args[:body].map { |job| job[:index][:_id] }
          expected_ids = issue_ids.map { |id| "issue_#{id}" }

          expect(actual_ids).to eq(expected_ids)

          allow(Issue.__elasticsearch__.client).to receive(:bulk).and_call_original if unstub

          response
        end
      end

      it 'does not retry if successful' do
        expect_indexing(issues.map(&:id), success_response, unstub: true)

        expect(subject.execute(project, true)).to eq(true)
      end

      it 'retries, and raises error if all retries fail' do
        expect_indexing(issues.map(&:id), failure_response)
        expect_indexing([issues.first.id], failure_response).exactly(described_class::IMPORT_RETRY_COUNT).times # Retry

        expect { subject.execute(project, true) }.to raise_error(described_class::ImportError)
      end

      it 'retries, and returns true if a retry is successful' do
        expect_indexing(issues.map(&:id), failure_response)
        expect_indexing([issues.first.id], success_response, unstub: true) # Retry

        expect(subject.execute(project, true)).to eq(true)
      end
    end
  end

  it 'indexes changes during indexing gap' do
    project = nil
    note = nil

    Sidekiq::Testing.inline! do
      project = create :project, :repository, :public
      note = create :note, project: project, note: 'note_1'
      Gitlab::Elastic::Helper.refresh_index
    end

    options = { project_ids: [project.id] }

    Sidekiq::Testing.disable! do
      note.update_columns(note: 'note_2')
      create :note, project: project, note: 'note_3'
    end

    expect(Note.elastic_search('note_1', options: options).present?).to eq(true)
    expect(Note.elastic_search('note_2', options: options).present?).to eq(false)
    expect(Note.elastic_search('note_3', options: options).present?).to eq(false)

    Sidekiq::Testing.inline! do
      expect(subject.execute(project, true)).to eq(true)
      Gitlab::Elastic::Helper.refresh_index
    end

    expect(Note.elastic_search('note_1', options: options).present?).to eq(false)
    expect(Note.elastic_search('note_2', options: options).present?).to eq(true)
    expect(Note.elastic_search('note_3', options: options).present?).to eq(true)
  end

  it 'skips records for which indexing is disabled' do
    project = nil

    Sidekiq::Testing.disable! do
      project = create :project, name: 'project_1'
    end

    expect(project).to receive(:use_elasticsearch?).and_return(false)

    Sidekiq::Testing.inline! do
      expect(subject.execute(project, true)).to eq(true)
      Gitlab::Elastic::Helper.refresh_index
    end

    expect(Project.elastic_search('project_1').present?).to eq(false)
  end

  context 'when updating an Issue' do
    context 'when changing the confidential value' do
      it 'updates issue notes excluding system notes' do
        project = create(:project, :public)
        issue = nil
        Sidekiq::Testing.disable! do
          issue = create(:issue, project: project, confidential: false)
          subject.execute(project, true)
          subject.execute(issue, false)
          create(:note, note: 'the_normal_note', noteable: issue, project: project)
          create(:note, note: 'the_system_note', system: true, noteable: issue, project: project)
        end

        options = { project_ids: [project.id] }

        Sidekiq::Testing.inline! do
          expect(subject.execute(issue, false, 'changed_fields' => ['confidential'])).to eq(true)
          Gitlab::Elastic::Helper.refresh_index
        end

        expect(Note.elastic_search('the_normal_note', options: options).present?).to eq(true)
        expect(Note.elastic_search('the_system_note', options: options).present?).to eq(false)
      end
    end

    context 'when changing the title' do
      it 'does not update issue notes' do
        issue = nil
        Sidekiq::Testing.disable! do
          issue = create(:issue, confidential: false)
          subject.execute(issue.project, true)
          subject.execute(issue, false)
          create(:note, note: 'the_normal_note', noteable: issue, project: issue.project)
        end

        options = { project_ids: [issue.project.id] }

        Sidekiq::Testing.inline! do
          expect(subject.execute(issue, false, 'changed_fields' => ['title'])).to eq(true)
          Gitlab::Elastic::Helper.refresh_index
        end

        expect(Note.elastic_search('the_normal_note', options: options).present?).to eq(false)
      end
    end
  end
end
