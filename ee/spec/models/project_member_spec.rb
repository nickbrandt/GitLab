# frozen_string_literal: true
require 'spec_helper'

describe ProjectMember do
  it { is_expected.to include_module(EE::ProjectMember) }

  it_behaves_like 'member validations' do
    let(:entity) { create(:project, group: group)}
  end
end
