# frozen_string_literal: true

require 'spec_helper'

describe Label do
  describe '#scoped_label?' do
    context 'with scoped_labels available' do
      before do
        stub_licensed_features(scoped_labels: true)
      end

      it 'returns false for unscoped labels' do
        expect(build(:label, title: 'some name').scoped_label?).to be_falsey
      end

      it 'returns true for scoped labels' do
        expect(build(:label, title: 'key::some name').scoped_label?).to be_truthy
      end

      it 'returns false for scoped labels without subject' do
        label = described_class.new(title: 'key::some name')

        expect(label.scoped_label?).to be_falsey
      end
    end

    context 'with scoped_labels not available' do
      before do
        stub_licensed_features(scoped_labels: false)
      end

      it 'returns false for scoped labels' do
        expect(build(:label, title: 'key::some name').scoped_label?).to be_falsey
      end
    end
  end

  describe '#scoped_label_key' do
    it 'returns key for scoped labels' do
      mappings = {
        'key1::key 2::some value' => 'key1::key 2::',
        'key1::some value' => 'key1::',
        '::some value' => '::',
        'some value' => nil
      }

      mappings.each do |title, expected_key|
        expect(build(:label, title: title).scoped_label_key).to eq(expected_key)
      end
    end
  end
end
