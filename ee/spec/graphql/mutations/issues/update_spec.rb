# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Issues::Update do
  it_behaves_like 'updating health status' do
    let(:resource) { create(:issue) }
    let(:user) { create(:user) }
  end
end
