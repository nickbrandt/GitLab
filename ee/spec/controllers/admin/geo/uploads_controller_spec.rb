# frozen_string_literal: true

require 'spec_helper'

describe Admin::Geo::UploadsController, :geo do
  include EE::GeoHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:synced_registry) { create(:geo_upload_registry, :with_file, :attachment, success: true) }
  let_it_be(:failed_registry) { create(:geo_upload_registry, :failed) }
  let_it_be(:never_registry) { create(:geo_upload_registry, :failed, retry_count: nil) }

  def css_id(registry)
    "#upload-#{registry.id}-header"
  end

  before do
    sign_in(admin)
  end

  shared_examples 'license required' do
    context 'without a valid license' do
      it 'redirects to license page with a flash message' do
        expect(subject).to redirect_to(admin_license_path)
        expect(flash[:alert]).to include('You need a different license to use Geo replication')
      end
    end
  end

  describe '#index' do
    subject { get :index }

    it_behaves_like 'license required'

    context 'with a valid license' do
      render_views

      before do
        stub_licensed_features(geo: true)
        stub_current_geo_node(secondary)
      end

      it 'renders the index template' do
        expect(subject).to have_gitlab_http_status(200)
        expect(subject).to render_template(:index)
      end

      context 'without sync_status specified' do
        it 'renders all registries' do
          expect(subject).to have_gitlab_http_status(200)
          expect(response.body).to have_css(css_id(synced_registry))
          expect(response.body).to have_css(css_id(failed_registry))
          expect(response.body).to have_css(css_id(never_registry))
        end
      end

      context 'with sync_status=synced' do
        subject { get :index, params: { sync_status: 'synced' } }

        it 'renders only synced registries' do
          expect(subject).to have_gitlab_http_status(200)
          expect(response.body).to have_css(css_id(synced_registry))
          expect(response.body).not_to have_css(css_id(failed_registry))
          expect(response.body).not_to have_css(css_id(never_registry))
        end
      end

      context 'with sync_status=failed' do
        subject { get :index, params: { sync_status: 'failed' } }

        it 'renders only failed registries' do
          expect(subject).to have_gitlab_http_status(200)
          expect(response.body).not_to have_css(css_id(synced_registry))
          expect(response.body).to have_css(css_id(failed_registry))
          expect(response.body).not_to have_css(css_id(never_registry))
        end
      end

      context 'with sync_status=never' do
        subject { get :index, params: { sync_status: 'never' } }

        it 'renders only never synced registries' do
          expect(subject).to have_gitlab_http_status(200)
          expect(response.body).not_to have_css(css_id(synced_registry))
          expect(response.body).not_to have_css(css_id(failed_registry))
          expect(response.body).to have_css(css_id(never_registry))
        end
      end
    end
  end

  describe '#destroy' do
    subject { delete :destroy, params: { id: registry } }

    it_behaves_like 'license required' do
      let(:registry) { create(:geo_upload_registry) }
    end

    context 'with a valid license' do
      before do
        stub_licensed_features(geo: true)
      end

      context 'with an orphaned registry' do
        let(:registry) { create(:geo_upload_registry, success: true) }

        it 'removes the registry' do
          registry.update_column(:file_id, -1)

          expect(subject).to redirect_to(admin_geo_uploads_path)
          expect(flash[:notice]).to include('was successfully removed')
          expect { Geo::UploadRegistry.find(registry.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context 'with a regular registry' do
        let(:registry) { create(:geo_upload_registry, :avatar, :with_file, success: true) }

        it 'does not delete the registry and gives an error' do
          expect(subject).to redirect_to(admin_geo_uploads_path)
          expect(flash[:alert]).to include('Could not remove tracking entry')
          expect { Geo::UploadRegistry.find(registry.id) }.not_to raise_error
        end
      end
    end
  end
end
