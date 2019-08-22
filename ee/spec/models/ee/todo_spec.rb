# frozen_string_literal: true

require 'spec_helper'

describe Todo do
  describe '#for_design?' do
    it 'returns true when target is a Design' do
      todo = build(:todo, target: build(:design))

      expect(todo.for_design?).to eq(true)
    end

    it 'returns false when target is not a Design' do
      todo = build(:todo)

      expect(todo.for_design?).to eq(false)
    end
  end
end
