# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GlRepository::RepoType do
  set(:project) { create(:project) }

  describe Gitlab::GlRepository::DESIGN do
    it_behaves_like 'a repo type' do
      let(:expected_identifier) { "design-#{project.id}" }
      let(:expected_id) { project.id.to_s }
      let(:expected_suffix) { ".design" }
      let(:expected_repository) { project.design_repository }
    end

    it "knows its type" do
      expect(described_class).to be_design
      expect(described_class).not_to be_project
    end
  end
end
