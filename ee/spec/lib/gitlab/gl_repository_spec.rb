# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GlRepository do
  describe '.parse' do
    let_it_be(:project) { create(:project, :repository) }

    it 'parses a design gl_repository' do
      expect(described_class.parse("design-#{project.id}")).to eq([project, EE::Gitlab::GlRepository::DESIGN])
    end
  end

  describe '.types' do
    it 'contains both the EE and CE repository types' do
      expected_types = Gitlab::GlRepository::TYPES.merge(EE::Gitlab::GlRepository::EE_TYPES)

      expect(described_class.types).to eq(expected_types)
    end
  end
end
