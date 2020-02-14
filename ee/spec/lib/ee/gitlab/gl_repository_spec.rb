# frozen_string_literal: true
require 'spec_helper'

describe ::EE::Gitlab::GlRepository do
  describe "DESIGN" do
    it "uses the design access checker" do
      expect(described_class::DESIGN.access_checker_class).to eq(::Gitlab::GitAccessDesign)
    end

    it "builds a design repository" do
      expect(described_class::DESIGN.repository_resolver.call(create(:project)))
        .to be_a(::DesignManagement::Repository)
    end
  end
end
