# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard todos' do
  let(:user) { create(:user) }
  let(:page_path) { dashboard_todos_path }

  it_behaves_like 'gold trial callout'
end
