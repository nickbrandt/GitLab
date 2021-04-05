# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TagsHelper do
  describe '#gl_dropdown_tags_enabled?' do
    context 'when the feature is enabled' do
      it 'returns true' do
        expect(helper.gldropdown_tags_enabled?).to be_truthy
      end
    end

    context 'when the feature is disabled' do
      it 'returns false' do
        stub_feature_flags(gldropdown_tags: false)
        expect(helper.gldropdown_tags_enabled?).to be_falsy
      end
    end
  end
end
