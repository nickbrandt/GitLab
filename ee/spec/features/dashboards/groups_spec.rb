# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard groups' do
  let(:user) { create(:user) }
  let(:page_path) { dashboard_groups_path }

  it_behaves_like 'gold trial callout'
end
