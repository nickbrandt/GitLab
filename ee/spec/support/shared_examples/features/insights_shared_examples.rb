# frozen_string_literal: true

RSpec.shared_examples 'Insights page' do
  set(:user) { create(:user) }

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

        expect(page).to have_gitlab_http_status(200)
        expect(page).to have_content('Insights')
      end

      context 'when the feature flag is disabled globally' do
        before do
          stub_feature_flags(insights: false)
        end

        it 'returns 404' do
          visit route

          expect(page).to have_gitlab_http_status(404)
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

        expect(page).to have_gitlab_http_status(404)
      end
    end
  end
end
