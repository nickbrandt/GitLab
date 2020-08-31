# frozen_string_literal: true

RSpec.shared_examples 'a cleanup container repository worker', :clean_gitlab_redis_shared_state do
  let_it_be(:repository) { create(:container_repository) }
  let(:project) { repository.project }
  let(:user) { project.owner }

  describe '#perform' do
    let(:service) { instance_double(Projects::ContainerRepository::CleanupTagsService) }

    subject { described_class.new }

    context 'bulk delete api' do
      let(:params) { { key: 'value', 'container_expiration_policy' => false } }

      it 'executes the destroy service' do
        expect(Projects::ContainerRepository::CleanupTagsService).to receive(:new)
          .with(project, user, params.merge('container_expiration_policy' => false))
          .and_return(service)
        expect(service).to receive(:execute)

        subject.perform(user.id, repository.id, params)
      end

      it 'does not raise error when user could not be found' do
        expect do
          subject.perform(-1, repository.id, params)
        end.not_to raise_error
      end

      it 'does not raise error when repository could not be found' do
        expect do
          subject.perform(user.id, -1, params)
        end.not_to raise_error
      end
    end

    context 'container expiration policy' do
      let(:params) { { key: 'value', 'container_expiration_policy' => true } }

      it 'executes the destroy service' do
        expect(Projects::ContainerRepository::CleanupTagsService).to receive(:new)
          .with(project, nil, params.merge('container_expiration_policy' => true))
          .and_return(service)

        expect(service).to receive(:execute)

        subject.perform(nil, repository.id, params)
      end
    end
  end
end
