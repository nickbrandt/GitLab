# frozen_string_literal: true
require 'spec_helper'

describe GroupMember do
  it { is_expected.to include_module(EE::GroupMember) }

  it_behaves_like 'member validations'
end
