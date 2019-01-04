# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard merge requests' do
  let(:user) { create(:user) }
  let(:page_path) { merge_requests_dashboard_path }

  it_behaves_like 'gold trial callout'
end
