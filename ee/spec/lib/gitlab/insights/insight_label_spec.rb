# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::InsightLabel do
  let(:label_title) { 'Bug' }
  let(:label_color) { 'red' }

  before do
    described_class.clear_registry!
  end

  describe '#initialize' do
    it 'accepts a title' do
      insight_label = described_class.new(label_title)

      expect(insight_label.title).to eq(label_title)
    end

    it 'accepts a color' do
      insight_label = described_class.new(label_title, label_color)

      expect(insight_label.color).to eq(label_color)
    end
  end

  describe '.[]' do
    it 'returns nil if the InsightLabel was not instantiated yet' do
      expect(described_class['Unknown'].title).to eq('Unknown')
    end

    it 'uses singleton per label for the current thread' do
      insight_label = described_class[label_title, label_color]

      expect(described_class[label_title]).to eq(insight_label)
    end

    it 'stringify the key' do
      insight_label = described_class[label_title, label_color]

      expect(described_class[label_title.to_sym]).to eq(insight_label)
    end

    it 'allows to set the color' do
      insight_label = described_class[label_title]

      expect(described_class[label_title, label_color].color).to eq(label_color)
    end
  end

  describe '#inspect' do
    it 'returns a nice string version of the object' do
      insight_label = described_class.new(label_title, label_color)

      expect(insight_label.inspect).to eq(%Q(#<Gitlab::Insights::InsightLabel @title="#{label_title}", @color="#{label_color}">))
    end
  end
end
