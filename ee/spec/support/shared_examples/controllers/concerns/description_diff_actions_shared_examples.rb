# frozen_string_literal: true

require 'spec_helper'

shared_examples DescriptionDiffActions do
  let(:base_params) { { namespace_id: project.namespace, project_id: project, id: issuable } }

  describe 'GET description_diff' do
    let_it_be(:version_1) { create(:description_version, issuable.class.name.underscore => issuable) }
    let_it_be(:version_2) { create(:description_version, issuable.class.name.underscore => issuable) }
    let_it_be(:version_3) { create(:description_version, issuable.class.name.underscore => issuable) }

    def get_description_diff(extra_params = {})
      get :description_diff, params: base_params.merge(extra_params)
    end

    context 'when license is available' do
      before do
        stub_licensed_features(epics: true, description_diffs: true)
      end

      it 'returns the diff with the previous version' do
        expect(Gitlab::Diff::CharDiff).to receive(:new).with(version_2.description, version_3.description).and_call_original

        get_description_diff(version_id: version_3)

        expect(response.status).to eq(200)
      end

      it 'returns the diff with the previous version of the specified start_version_id' do
        expect(Gitlab::Diff::CharDiff).to receive(:new).with(version_1.description, version_3.description).and_call_original

        get_description_diff(version_id: version_3, start_version_id: version_2)

        expect(response.status).to eq(200)
      end

      context 'when description version is from another issuable' do
        it 'returns 404' do
          other_version = create(:description_version)

          get_description_diff(version_id: other_version)

          expect(response.status).to eq(404)
        end
      end

      context 'when start_version_id is from another issuable' do
        it 'returns 404' do
          other_version = create(:description_version)

          get_description_diff(version_id: version_3, start_version_id: other_version)

          expect(response.status).to eq(404)
        end
      end
    end

    context 'when license is not available' do
      before do
        stub_licensed_features(epics: true, description_diffs: false)
      end

      it 'returns 404' do
        get_description_diff(version_id: version_3)

        expect(response.status).to eq(404)
      end
    end
  end
end
