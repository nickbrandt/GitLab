require 'spec_helper'

describe Projects::PipelinesController do
  set(:user) { create(:user) }
  set(:project) { create(:project, :repository) }
  set(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

  before do
    project.add_developer(user)

    sign_in(user)
  end

  describe 'GET show.json' do
    set(:source_project) { create(:project) }
    set(:target_project) { create(:project) }
    set(:root_pipeline) { create_pipeline(project) }
    set(:source_pipeline) { create_pipeline(source_project) }
    set(:source_of_source_pipeline) { create_pipeline(source_project) }
    set(:target_pipeline) { create_pipeline(target_project) }
    set(:target_of_target_pipeline) { create_pipeline(target_project) }

    before do
      create_link(source_of_source_pipeline, source_pipeline)
      create_link(source_pipeline, root_pipeline)
      create_link(root_pipeline, target_pipeline)
      create_link(target_pipeline, target_of_target_pipeline)
    end

    shared_examples 'not expanded' do
      let(:expected_stages) { be_nil }

      it 'does return base details' do
        get_pipeline_json(root_pipeline)

        expect(json_response['triggered_by']).to include('id' => source_pipeline.id)
        expect(json_response['triggered']).to contain_exactly(
          include('id' => target_pipeline.id))
      end

      it 'does not expand triggered_by pipeline' do
        get_pipeline_json(root_pipeline)

        triggered_by = json_response['triggered_by']
        expect(triggered_by['triggered_by']).to be_nil
        expect(triggered_by['triggered']).to be_nil
        expect(triggered_by['details']['stages']).to expected_stages
      end

      it 'does not expand triggered pipelines' do
        get_pipeline_json(root_pipeline)

        first_triggered = json_response['triggered'].first
        expect(first_triggered['triggered_by']).to be_nil
        expect(first_triggered['triggered']).to be_nil
        expect(first_triggered['details']['stages']).to expected_stages
      end
    end

    shared_examples 'expanded' do
      it 'does return base details' do
        get_pipeline_json(root_pipeline)

        expect(json_response['triggered_by']).to include('id' => source_pipeline.id)
        expect(json_response['triggered']).to contain_exactly(
          include('id' => target_pipeline.id))
      end

      it 'does expand triggered_by pipeline' do
        get_pipeline_json(root_pipeline)

        triggered_by = json_response['triggered_by']
        expect(triggered_by['triggered_by']).to include(
          'id' => source_of_source_pipeline.id)
        expect(triggered_by['details']['stages']).not_to be_nil
      end

      it 'does not recursively expand triggered_by' do
        get_pipeline_json(root_pipeline)

        triggered_by = json_response['triggered_by']
        expect(triggered_by['triggered']).to be_nil
      end

      it 'does expand triggered pipelines' do
        get_pipeline_json(root_pipeline)

        first_triggered = json_response['triggered'].first
        expect(first_triggered['triggered']).to contain_exactly(
          include('id' => target_of_target_pipeline.id))
        expect(first_triggered['details']['stages']).not_to be_nil
      end

      it 'does not recursively expand triggered' do
        get_pipeline_json(root_pipeline)

        first_triggered = json_response['triggered'].first
        expect(first_triggered['triggered_by']).to be_nil
      end
    end

    context 'when it does have permission to read other projects' do
      before do
        source_project.add_developer(user)
        target_project.add_developer(user)
      end

      context 'when not-expanding any pipelines' do
        let(:expanded) { nil }

        it_behaves_like 'not expanded'
      end

      context 'when expanding non-existing pipeline' do
        let(:expanded) { [-1] }

        it_behaves_like 'not expanded'
      end

      context 'when expanding pipeline that is not directly expandable' do
        let(:expanded) { [source_of_source_pipeline.id, target_of_target_pipeline.id] }

        it_behaves_like 'not expanded'
      end

      context 'when expanding self' do
        let(:expanded) { [root_pipeline.id] }

        context 'it does not recursively expand pipelines' do
          it_behaves_like 'not expanded'
        end
      end

      context 'when expanding source and target pipeline' do
        let(:expanded) { [source_pipeline.id, target_pipeline.id] }

        it_behaves_like 'expanded'

        context 'when expand depth is limited to 1' do
          before do
            stub_const('TriggeredPipelineEntity::MAX_EXPAND_DEPTH', 1)
          end

          it_behaves_like 'not expanded' do
            # We expect that triggered/triggered_by is not expanded,
            # but we still return details.stages for that pipeline
            let(:expected_stages) { be_a(Array) }
          end
        end
      end

      context 'when expanding all' do
        let(:expanded) do
          [
            source_of_source_pipeline.id,
            source_pipeline.id,
            root_pipeline.id,
            target_pipeline.id,
            target_of_target_pipeline.id
          ]
        end

        it_behaves_like 'expanded'
      end
    end

    context 'when does not have permission to read other projects' do
      let(:expanded) { [source_pipeline.id, target_pipeline.id] }

      it_behaves_like 'not expanded'
    end

    def create_pipeline(project)
      create(:ci_empty_pipeline, project: project).tap do |pipeline|
        create(:ci_build, pipeline: pipeline, stage: 'test', name: 'rspec')
      end
    end

    def create_link(source_pipeline, pipeline)
      source_pipeline.sourced_pipelines.create!(
        source_job: source_pipeline.builds.all.sample,
        source_project: source_pipeline.project,
        project: pipeline.project,
        pipeline: pipeline
      )
    end

    def get_pipeline_json(pipeline)
      params = {
        namespace_id: pipeline.project.namespace,
        project_id: pipeline.project,
        id: pipeline,
        expanded: expanded
      }

      get :show, params: params.compact, format: :json
    end
  end

  describe 'GET security' do
    context 'with a sast artifact' do
      before do
        create(:ee_ci_build, :legacy_sast, pipeline: pipeline)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true)

          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template :show
        end
      end

      context 'with feature disabled' do
        before do
          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end

    context 'without sast artifact' do
      context 'with feature enabled' do
        before do
          stub_licensed_features(sast: true)

          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :security, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end

  describe 'GET licenses' do
    context 'with a license management artifact' do
      before do
        build = create(:ci_build, pipeline: pipeline)
        create(:ee_ci_job_artifact, :license_management, job: build)
      end

      context 'with feature enabled' do
        before do
          stub_licensed_features(license_management: true)

          get :licenses, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to have_gitlab_http_status(200)
          expect(response).to render_template :show
        end
      end

      context 'with feature disabled' do
        before do
          get :licenses, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end

    context 'without license management artifact' do
      context 'with feature enabled' do
        before do
          stub_licensed_features(license_management: true)

          get :licenses, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end

      context 'with feature disabled' do
        before do
          get :licenses, params: { namespace_id: project.namespace, project_id: project, id: pipeline }
        end

        it do
          expect(response).to redirect_to(pipeline_path(pipeline))
        end
      end
    end
  end
end
