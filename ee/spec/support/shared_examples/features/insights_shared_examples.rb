# frozen_string_literal: true

RSpec.shared_examples 'Insights page' do
  let_it_be(:user) { create(:user) }

  context 'as a permitted user' do
    before(:context) do
      entity.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    context 'with correct license' do
      before do
        stub_licensed_features(insights: true)
      end

      it 'has correct title' do
        visit route

        expect(page).to have_gitlab_http_status(:ok)
        expect(page).to have_content('Insights')
      end

      context 'hash fragment navigation', :js do
        let(:config) { entity.insights_config }
        let(:non_default_tab_id) { config.keys.last }
        let(:non_default_tab_title) { config[non_default_tab_id][:title] }
        let(:hash_fragment) { "#/#{non_default_tab_id}" }
        let(:route) { path + hash_fragment }

        before do
          visit route

          wait_for_requests
        end

        it 'loads the correct page' do
          page.within(".insights-container") do
            expect(page).to have_content(non_default_tab_title)
          end
        end
      end

      context 'when the feature flag is disabled globally' do
        before do
          stub_feature_flags(insights: false)
        end

        it 'returns 404' do
          visit route

          expect(page).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'without correct license' do
      before do
        stub_feature_flags(insights: { enabled: false, thing: entity })
        stub_licensed_features(insights: false)
      end

      it 'returns 404' do
        visit route

        expect(page).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
