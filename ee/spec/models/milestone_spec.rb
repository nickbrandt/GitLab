# frozen_string_literal: true

require 'spec_helper'

describe Milestone do
  describe "Associations" do
    it { is_expected.to have_many(:boards) }
  end
end
