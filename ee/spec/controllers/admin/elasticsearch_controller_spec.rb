# frozen_string_literal: true

require 'spec_helper'

describe Admin::ElasticsearchController do
  let(:admin) { create(:admin) }

  describe 'POST #enqueue_index' do
    before do
      sign_in(admin)
    end

    it 'starts indexing' do
      expect(Gitlab::Elastic::Helper.default).to(receive(:index_exists?)).and_return(true)
      expect_next_instance_of(::Elastic::IndexProjectsService) do |service|
        expect(service).to receive(:execute)
      end

      post :enqueue_index

      expect(controller).to set_flash[:notice].to include('/admin/sidekiq/queues/elastic_full_index')
      expect(response).to redirect_to integrations_admin_application_settings_path(anchor: 'js-elasticsearch-settings')
    end

    context 'without an index' do
      before do
        allow(Gitlab::Elastic::Helper.default).to(receive(:index_exists?)).and_return(false)
      end

      it 'does nothing and returns 404' do
        expect(::Elastic::IndexProjectsService).not_to receive(:new)

        post :enqueue_index

        expect(controller).to set_flash[:warning].to include('create an index before enabling indexing')
        expect(response).to redirect_to integrations_admin_application_settings_path(anchor: 'js-elasticsearch-settings')
      end
    end

    context 'when feature is disabled' do
      it 'does nothing and returns 404' do
        stub_feature_flags(elasticsearch_web_indexing: false)

        expect(::Elastic::IndexProjectsService).not_to receive(:new)

        post :enqueue_index

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
