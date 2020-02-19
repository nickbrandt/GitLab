# frozen_string_literal: true

require 'spec_helper'

describe UserDetail do
  it { is_expected.to belong_to(:user) }
end
