# frozen_string_literal: true

require 'spec_helper'

describe ProjectHook do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:project_hook, project: create(:project)) }
  end
end
