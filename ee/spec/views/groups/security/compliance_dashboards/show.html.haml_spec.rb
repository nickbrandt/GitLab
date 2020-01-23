# frozen_string_literal: true

require 'spec_helper'

describe 'groups/security/compliance_dashboards/show.html.haml' do
  set(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)

    assign(:group, group)
    allow(view).to receive(:current_user) { user }
  end

  it 'shows empty state if there are no merge requests' do
    render

    expect(rendered).to have_css("div.empty-state")
  end

  context 'when there are merge requests' do
    let(:mr) { create(:merge_request, :merged) }

    before do
      mr.metrics.update!(merged_at: 1.day.ago)
      assign(:merge_requests, Kaminari.paginate_array([mr]).page(1))
    end

    it 'shows merge requests' do
      render

      expect(rendered).to have_css(".merge-request-title.title")
    end
  end
end
