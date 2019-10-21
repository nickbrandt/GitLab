# frozen_string_literal: true

require 'spec_helper'

describe Ci::Sources::Pipeline do
  it { is_expected.to belong_to(:source_bridge) }
end
