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
          subject.execute(object, true)
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'updates the index when object is changed' do
        object = nil

        Sidekiq::Testing.disable! do
          object = create(type)
          subject.execute(object, true)
          object.update(attribute => "new")
        end

        expect do
          subject.execute(object, false)
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
      end
    end
  end

  it 'indexes all nested objects for a Project' do
    # To be able to access it outside the following block
    project = nil

    Sidekiq::Testing.disable! do
      project = create :project, :repository
      create :issue, project: project
      create :milestone, project: project
      create :note, project: project
      create :merge_request, target_project: project, source_project: project
      create :project_snippet, project: project
    end

    expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id).and_call_original

    # Nothing should be in the index at this point
    expect(Elasticsearch::Model.search('*').total_count).to be(0)

    Sidekiq::Testing.inline! do
      subject.execute(project, true)
    end
    Gitlab::Elastic::Helper.refresh_index

    ## All database objects + data from repository. The absolute value does not matter
    expect(Elasticsearch::Model.search('*').total_count).to be > 40
  end

  it 'indexes changes during indexing gap' do
    project = nil
    note = nil

    Sidekiq::Testing.inline! do
      project = create :project, :repository
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
      subject.execute(project, true)
      Gitlab::Elastic::Helper.refresh_index
    end

    expect(Note.elastic_search('note_1', options: options).present?).to eq(false)
    expect(Note.elastic_search('note_2', options: options).present?).to eq(true)
    expect(Note.elastic_search('note_3', options: options).present?).to eq(true)
  end
end
