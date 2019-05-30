# frozen_string_literal: true

require 'spec_helper'

describe BlockingMergeRequestEntity do
  set(:merge_request) { create(:merge_request) }
  set(:user) { create(:user) }

  let(:web_url) { Gitlab::Routing.url_helpers.project_merge_request_path(merge_request.project, merge_request) }
  let(:request) { double('request', current_user: user) }
  let(:extra_options) { {} }

  subject(:entity) do
    options = extra_options.merge(current_user: user, request: request)
    described_class.new(merge_request, options)
  end

  it 'exposes simple attributes' do
    expect(entity.as_json).to include(
      id: merge_request.id,
      iid: merge_request.iid,
      title: merge_request.title,
      state: merge_request.state,
      created_at: merge_request.created_at,
      merged_at: merge_request.merged_at,
      closed_at: merge_request.metrics.latest_closed_at,
      web_url: web_url
    )
  end

  describe '#reference' do
    let(:other_project) { create(:project) }

    subject { entity.as_json[:reference] }

    it { is_expected.to eq(merge_request.to_reference) }

    context 'from another project' do
      let(:extra_options) { { from_project: other_project } }

      it 'includes the fully-qualified reference when needed' do
        is_expected.to eq(merge_request.to_reference(other_project))
      end
    end
  end
end
