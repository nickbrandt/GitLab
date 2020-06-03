# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Approval do
  subject { create(:approval) }

  it { is_expected.to be_valid }
end
