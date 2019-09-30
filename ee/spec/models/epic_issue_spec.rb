# frozen_string_literal: true

require 'spec_helper'

describe EpicIssue do
  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:epic) { create(:epic) }
      let(:factory) { :epic_issue }
      let(:default_params) { { epic: epic } }
    end
  end
end
