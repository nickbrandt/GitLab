# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::Renderer do
  describe '.markdown' do
    it 'delegates to MarkupHelper.markdown_field' do
      object = Object.new
      field = :field

      expect(MarkupHelper)
        .to receive(:markdown_field)
        .with(object, field)

      described_class.markdown(object, field)
    end
  end
end
