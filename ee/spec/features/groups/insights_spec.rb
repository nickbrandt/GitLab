# frozen_string_literal: true

require 'spec_helper'

describe 'Group Insights' do
  it_behaves_like 'Insights page' do
    set(:entity) { create(:group) }
    let(:route) { url_for([entity, :insights]) }
  end
end
