# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::WikisController do
  it_behaves_like 'wiki controller actions' do
    let(:container) { create(:group, :public) }
    let(:routing_params) { { group_id: container } }

    before do
      container.add_owner(user)
      stub_feature_flags(group_wiki: container)
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(group_wiki: false)
      end

      using RSpec::Parameterized::TableSyntax

      where(:method, :action) do
        :get    | :new
        :get    | :pages
        :post   | :create
        :get    | :show
        :get    | :edit
        :get    | :history
        :post   | :preview_markdown
        :put    | :update
        :delete | :destroy
      end

      with_them do
        it 'returns a 404 error' do
          process action, method: method, params: routing_params.merge(id: 'page')

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
