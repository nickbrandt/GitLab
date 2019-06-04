# frozen_string_literal: true

require 'rails_helper'

describe EE::Noteable do
  subject(:klazz) { Class.new { include Noteable } }

  describe '.replyable_types' do
    it 'adds Epic to replyable_types after being included' do
      expect(klazz.replyable_types).to include("Epic")
    end
  end

  describe '.resolvable_types' do
    it 'includes design management' do
      expect(klazz.resolvable_types).to include('DesignManagement::Design')
    end
  end
end
