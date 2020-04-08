# frozen_string_literal: true

require 'spec_helper'

describe 'projects/merge_requests/show.html.haml' do
  include_context 'merge request show action'

  context 'when merge request is created by a GitLab team member' do
    let(:user) { create(:user, email: 'test@gitlab.com') }

    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'renders an employee badge next to their name' do
      render

      expect(rendered).to have_selector('[aria-label="GitLab Team Member"]')
    end
  end
end
