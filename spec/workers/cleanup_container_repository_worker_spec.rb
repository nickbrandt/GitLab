# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CleanupContainerRepositoryWorker, :clean_gitlab_redis_shared_state do
  let_it_be(:repository) { create(:container_repository) }
  let(:project) { repository.project }
  let(:user) { project.owner }
  let(:user_id) { user.id }
  let(:repository_id) { repository.id }
  let(:params) { {} }
  let(:job_args) { [user_id, repository_id, params] }

  describe '#perform' do
    let(:service) { instance_double(Projects::ContainerRepository::CleanupTagsService) }
    let(:manifest) { { 'tags' => %w(A B C) } }

    subject { described_class.new.perform(*job_args) }

    context 'bulk delete api' do
      let(:params) { { key: 'value', 'name_regex_delete' => '.*', 'container_expiration_policy' => false } }

      it 'executes the cleanup tags service' do
        expect(Projects::ContainerRepository::CleanupTagsService).to receive(:new)
          .with(project, user, params)
          .and_return(service)

        expect(service).to receive(:execute)

        subject
      end

      it_behaves_like 'an idempotent worker' do
        before do
          stub_container_registry_config(enabled: true, api_url: 'http://test', key: 'spec/fixtures/x509_certificate_pk.key')

          allow_next_instance_of(ContainerRegistry::Client) do |client|
            allow(client).to receive(:supports_tag_delete?).and_return(true)
            allow(client).to receive(:repository_tags).and_return(manifest)
            allow(client).to receive(:delete_if_exists).and_return(true)
          end
        end
      end

      context 'with an invalid user_id' do
        let(:user_id) { -1 }

        it { expect { subject }.not_to raise_error }
      end

      context 'with an invalid repository id' do
        let(:repository_id) { -1 }

        it { expect { subject }.not_to raise_error }
      end
    end

    context 'container expiration policy' do
      let(:params) { { key: 'value', 'name_regex_delete' => '.*', 'container_expiration_policy' => true } }

      it 'executes the cleanup tags service' do
        expect(Projects::ContainerRepository::CleanupTagsService).to receive(:new)
          .and_return(service)

        expect(service).to receive(:execute)

        subject
      end

      it_behaves_like 'an idempotent worker' do
        before do
          stub_container_registry_config(enabled: true, api_url: 'http://test', key: 'spec/fixtures/x509_certificate_pk.key')

          allow_next_instance_of(ContainerRegistry::Client) do |client|
            allow(client).to receive(:supports_tag_delete?).and_return(true)
            allow(client).to receive(:repository_tags).and_return(manifest)
            allow(client).to receive(:delete_if_exists).and_return(true)
          end
        end
      end
    end

    context 'with feature flag container_registry_expiration_policies_throttling enabled' do
      let(:params) { { 'container_expiration_policy' => true } }

      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: true)
        allow(Projects::ContainerRepository::CleanupTagsService).to receive(:new).and_return(service)
        allow(service).to receive(:execute)
      end

      context 'without a jids redis key' do
        it 'do not access redis' do
          expect(Sidekiq).not_to receive(:redis)

          subject
        end
      end

      context 'with a jids redis key' do
        let(:redis_key) { 'jids' }
        let(:jid) { 1234567 }
        let(:params) { { 'container_expiration_policy' => true, 'jids_redis_key' => redis_key } }
        let(:expected_jids_list_size) { 0 }

        before do
          Sidekiq.redis do |redis|
            redis.sadd(redis_key, jid)
          end
        end

        after do
          Sidekiq.redis do |redis|
            expect(redis.smembers(redis_key).size).to eq(expected_jids_list_size)
          end
        end

        context 'containing the jid' do
          before do
            allow_next_instance_of(CleanupContainerRepositoryWorker) do |worker|
              allow(worker).to receive(:jid).and_return(jid)
            end
          end

          it 'removes the jid from the jids list' do
            Sidekiq.redis do |redis|
              expect(redis).to receive(:srem).and_call_original
            end

            subject
          end

          context 'with an exception' do
            it 'removes the jid from the jids list' do
              allow(::Projects::ContainerRepository::CleanupTagsService).to receive(:new) do
                raise ArgumentError
              end

              Sidekiq.redis do |redis|
                expect(redis).to receive(:srem).and_call_original
              end

              expect { subject }.to raise_error(ArgumentError)
            end
          end
        end

        context 'not containing the jid' do
          let(:expected_jids_list_size) { 1 }

          it 'does not remove the other jids from the jids list' do
            allow_next_instance_of(CleanupContainerRepositoryWorker) do |worker|
              allow(worker).to receive(:jid).and_return(5555)
            end

            Sidekiq.redis do |redis|
              expect(redis).to receive(:srem).and_call_original
            end

            subject
          end
        end
      end
    end
  end
end
