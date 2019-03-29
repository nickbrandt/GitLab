require 'spec_helper'

describe ElasticIndexerWorker, :elastic do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)

    Elasticsearch::Model.client =
      Gitlab::Elastic::Client.build(Gitlab::CurrentSettings.elasticsearch_config)
  end

  it 'returns true if ES disabled' do
    stub_ee_application_setting(elasticsearch_indexing: false)

    expect_any_instance_of(Elasticsearch::Model).not_to receive(:__elasticsearch__)

    expect(subject.perform("index", "Milestone", 1, 1)).to be_truthy
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
          subject.perform("index", name, object.id, object.es_id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('*').records.size }.by(1)
      end

      it 'updates the index when object is changed' do
        object = nil

        Sidekiq::Testing.disable! do
          object = create(type)
          subject.perform("index", name, object.id, object.es_id)
          object.update(attribute => "new")
        end

        expect do
          subject.perform("update", name, object.id, object.es_id)
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('new').records.size }.by(1)
      end

      it 'deletes from index when an object is deleted' do
        object = nil

        Sidekiq::Testing.disable! do
          object = create(type)
          subject.perform("index", name, object.id, object.es_id)
          Gitlab::Elastic::Helper.refresh_index
          object.destroy
        end

        expect do
          subject.perform("delete", name, object.id, object.es_id, { 'es_parent' => object.es_parent })
          Gitlab::Elastic::Helper.refresh_index
        end.to change { Elasticsearch::Model.search('*').total_count }.by(-1)
      end
    end
  end

  it 'deletes a project with all nested objects' do
    project, issue, milestone, note, merge_request = nil

    Sidekiq::Testing.disable! do
      project = create :project, :repository
      subject.perform("index", "Project", project.id, project.es_id)

      issue = create :issue, project: project
      subject.perform("index", "Issue", issue.id, issue.es_id)

      milestone = create :milestone, project: project
      subject.perform("index", "Milestone", milestone.id, milestone.es_id)

      note = create :note, project: project
      subject.perform("index", "Note", note.id, note.es_id)

      merge_request = create :merge_request, target_project: project, source_project: project
      subject.perform("index", "MergeRequest", merge_request.id, merge_request.es_id)
    end

    ElasticCommitIndexerWorker.new.perform(project.id)
    Gitlab::Elastic::Helper.refresh_index

    ## All database objects + data from repository. The absolute value does not matter
    expect(Elasticsearch::Model.search('*').total_count).to be > 40

    subject.perform("delete", "Project", project.id, project.es_id)
    Gitlab::Elastic::Helper.refresh_index

    expect(Elasticsearch::Model.search('*').total_count).to be(0)
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
      subject.perform("index", "Project", project.id, project.es_id)
    end
    Gitlab::Elastic::Helper.refresh_index

    ## All database objects + data from repository. The absolute value does not matter
    expect(Elasticsearch::Model.search('*').total_count).to be > 40
  end
end
