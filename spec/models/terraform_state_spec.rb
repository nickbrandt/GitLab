# frozen_string_literal: true

require 'spec_helper'

describe TerraformState do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to validate_presence_of(:project_id) }
end
