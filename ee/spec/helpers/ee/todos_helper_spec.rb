# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::TodosHelper do
  describe '#todo_types_options' do
    it 'includes options for an epic todo' do
      expect(helper.todo_types_options).to include(
        { id: 'Epic', text: 'Epic' }
      )
    end
  end
end
