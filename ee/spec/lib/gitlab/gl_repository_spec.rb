# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GlRepository do
  describe '.parse' do
    set(:project) { create(:project, :repository) }

    it 'parses a design gl_repository' do
      expect(described_class.parse("design-#{project.id}")).to eq([project, EE::Gitlab::GlRepository::DESIGN])
    end
  end
end
