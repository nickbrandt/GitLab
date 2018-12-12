# frozen_string_literal: true

require 'spec_helper'

describe TabHelper do
  describe '#project_tab_class' do
    it 'returns "active" for the push rules controller' do
      controller = instance_double(
        'controller',
        controller_name: 'push_rules',
        controller_path: '/push_rules/foo'
      )

      allow(helper)
        .to receive(:controller)
        .and_return(controller)

      expect(helper.project_tab_class).to eq('active')
    end
  end
end
