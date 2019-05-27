# frozen_string_literal: true

require 'spec_helper'

describe BoardSerializer do
  let(:resource) { create(:board) }
  let(:json_entity) do
    described_class.new
      .represent(resource, serializer: serializer)
      .with_indifferent_access
  end

  context 'serialization via CE' do
    let(:serializer) { 'sidebar' }

    it 'matches issue_sidebar json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar', dir: 'ee')
    end
  end

  context 'serialization via EE' do
    let(:serializer) { 'sidebar_extras' }

    it 'matches issue_sidebar_extras json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar_extras', dir: 'ee')
    end
  end
end
