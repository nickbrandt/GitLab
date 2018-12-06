# frozen_string_literal: true

require 'spec_helper'

describe Projects::WebIdeTerminalsController do
  let(:owner) { create(:owner) }
  let(:admin) { create(:admin) }
  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:project) { create(:project, :private, :repository, namespace: owner.namespace) }
  let(:pipeline) { create(:ci_pipeline, project: project, source: :webide, config_source: :webide_source, user: user) }
  let(:job) { create(:ci_build, pipeline: pipeline, user: user, project: project) }
  let(:user) { maintainer }

  before do
    stub_licensed_features(web_ide_terminal: true)

    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)

    sign_in(user)
  end

  shared_examples 'terminal access rights' do
    context 'with admin' do
      let(:user) { admin }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with owner' do
      let(:user) { owner }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with maintainer' do
      let(:user) { maintainer }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with developer' do
      let(:user) { developer }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with guest' do
      let(:user) { guest }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with non member' do
      let(:user) { create(:user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  shared_examples 'when pipeline is not from a webide source' do
    context 'with admin' do
      let(:user) { admin }
      let(:pipeline) { create(:ci_pipeline, project: project, source: :chat, user: user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET show' do
    before do
      get(:show, namespace_id: project.namespace.to_param, project_id: project, id: job.id)
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'
  end

  describe 'POST check_config' do
    let(:result) { { status: :success } }

    before do
      allow_any_instance_of(::Ci::WebIdeConfigService)
        .to receive(:execute).and_return(result)

      post :check_config, namespace_id: project.namespace.to_param,
                          project_id: project.to_param,
                          branch: 'master'
    end

    it_behaves_like 'terminal access rights'

    context 'when invalid config file' do
      let(:user) { admin }
      let(:result) { { status: :error } }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  describe 'POST create' do
    let(:branch) { 'master' }

    subject do
      post :create, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    branch: branch
    end

    context 'access rights' do
      let(:build) { create(:ci_build, project: project) }
      let(:pipeline) { build.pipeline }

      before do
        allow_any_instance_of(::Ci::CreateWebIdeTerminalService)
          .to receive(:execute).and_return(status: :success, pipeline: pipeline)

        subject
      end

      it_behaves_like 'terminal access rights'
    end

    context 'when branch does not exist' do
      let(:user) { admin }
      let(:branch) { 'foobar' }

      it 'returns 400' do
        subject

        expect(response).to have_gitlab_http_status(400)
      end
    end

    context 'when there is an error creating the job' do
      let(:user) { admin }

      it 'returns 400' do
        allow_any_instance_of(::Ci::CreateWebIdeTerminalService)
          .to receive(:execute).and_return(status: :error, message: 'foobar')

        subject

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  describe 'POST cancel' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline, user: user, project: project) }

    before do
      post(:cancel, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    id: job.id)
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    context 'when job is not cancelable' do
      let!(:job) { create(:ci_build, :failed, pipeline: pipeline, user: user) }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  describe 'POST retry' do
    let(:job) { create(:ci_build, :failed, pipeline: pipeline, user: user, project: project) }

    before do
      post(:retry, namespace_id: project.namespace.to_param,
                   project_id: project.to_param,
                   id: job.id)
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    context 'when job is not retryable' do
      let!(:job) { create(:ci_build, :running, pipeline: pipeline, user: user) }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end
  end
end
