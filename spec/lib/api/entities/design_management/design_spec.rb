# frozen_string_literal: true

require 'spec_helper'

describe API::Entities::DesignManagement::Design do
  let_it_be(:design) { create(:design) }
  let(:entity) { described_class.new(design, request: double) }

  subject { entity.as_json }

  it 'has the correct attributes' do
    # TODO this test is being temporarily skipped unless run in EE,
    # as we are in the process of moving Design Management to FOSS in 13.0
    # in steps. In the current step the routes have not yet been moved,
    # which `Gitlab::UrlBuilder` calls in this test.
    #
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283.
    skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

    expect(subject).to eq({
      id: design.id,
      project_id: design.project_id,
      filename: design.filename,
      image_url: ::Gitlab::UrlBuilder.build(design)
    })
  end
end
