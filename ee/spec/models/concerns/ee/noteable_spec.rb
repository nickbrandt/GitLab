# frozen_string_literal: true

require 'rails_helper'

describe EE::Noteable do
  describe '.replyable_types' do
    it 'adds Epic to replyable_types after being included' do
      class SomeClass
        include Noteable
      end

      expect(SomeClass.replyable_types).to include("Epic")
    end
  end
end
