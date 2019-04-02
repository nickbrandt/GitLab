# frozen_string_literal: true

require 'spec_helper'

describe Ci::Variable do
  subject { build(:ci_variable) }

  describe 'validations' do
    it { is_expected.to include_module(HasEnvironmentScope) }
  end

  it do
    is_expected.to validate_uniqueness_of(:key)
      .scoped_to(:project_id, :environment_scope)
      .with_message(/\(\w+\) has already been taken/)
  end
end
