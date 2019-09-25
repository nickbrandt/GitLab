# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UrlBuilder do
  describe '.build' do
    context 'when passing a DesignManagement::Design' do
      it 'returns a proper URL' do
        design = build_stubbed(:design)

        url = described_class.build(design)

        expect(url).to eq "#{Settings.gitlab['url']}/#{design.project.full_path}/-/designs/#{design.id}"
      end
    end
  end
end
