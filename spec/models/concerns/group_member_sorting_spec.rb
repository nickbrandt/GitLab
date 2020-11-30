# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMemberSorting do
  describe '.sorting_for' do
    let(:sort_value) { nil }
    let(:sortable_class) { GroupMember }

    subject { sortable_class.sorting_for(sort_value) }

    context 'sorting is not passed in' do
      it 'returns name_asc' do
        expect(subject).to eq('name_asc')
      end
    end

    context 'sorting is passed in' do
      let(:sort_value) { 'name_desc' }

      it 'returns that sorting' do
        expect(subject).to eq(sort_value)
      end
    end
  end
end
