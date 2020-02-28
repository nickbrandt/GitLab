# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GlRepository::RepoType do
  let_it_be(:project) { create(:project) }

  describe Gitlab::GlRepository::DESIGN do
    it_behaves_like 'a repo type' do
      let(:expected_identifier) { "design-#{project.id}" }
      let(:expected_id) { project.id.to_s }
      let(:expected_suffix) { '.design' }
      let(:expected_repository) { project.design_repository }
      let(:expected_container) { project }
    end

    it 'knows its type' do
      expect(described_class).to be_design
      expect(described_class).not_to be_project
      expect(described_class).not_to be_wiki
      expect(described_class).not_to be_snippet
    end

    it 'checks if repository path is valid' do
      expect(described_class.valid?(project.design_repository.full_path)).to be_truthy
      expect(described_class.valid?(project.repository.full_path)).to be_falsey
      expect(described_class.valid?(project.wiki.repository.full_path)).to be_falsey
    end
  end
end
