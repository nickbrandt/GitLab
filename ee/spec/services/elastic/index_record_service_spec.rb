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
        subject.execute(project, true)
      end
      Gitlab::Elastic::Helper.refresh_index

      ## All database objects + data from repository. The absolute value does not matter
      expect(Elasticsearch::Model.search('*').total_count).to be > 40
    end

    it 'does not index records not associated with the project' do
      other_project = create :project

      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(other_project.id).and_call_original
      expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(other_project.id, nil, nil, true).and_call_original

      Sidekiq::Testing.inline! do
        subject.execute(other_project, true)
      end
      Gitlab::Elastic::Helper.refresh_index

      # Only the project itself should be in the index
      expect(Elasticsearch::Model.search('*').total_count).to be 1
      expect(Project.elastic_search('*').records).to contain_exactly(other_project)
    end
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

  it 'skips records for which indexing is disabled' do
    project = nil

    Sidekiq::Testing.disable! do
      project = create :project, name: 'project_1'
    end

    expect(project).to receive(:use_elasticsearch?).and_return(false)

    Sidekiq::Testing.inline! do
      subject.execute(project, true)
      Gitlab::Elastic::Helper.refresh_index
    end

    expect(Project.elastic_search('project_1').present?).to eq(false)
  end
end
