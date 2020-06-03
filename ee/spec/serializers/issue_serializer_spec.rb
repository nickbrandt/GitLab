# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueSerializer do
  let(:resource) { create(:issue) }
  let(:user)     { create(:user) }
  let(:json_entity) do
    described_class.new(current_user: user)
      .represent(resource, serializer: serializer)
      .with_indifferent_access
  end

  before do
    epic = create(:epic, :use_fixed_dates)
    create(:epic_issue, issue: resource, epic: epic)
  end

  context 'sidebar issue serialization' do
    let(:serializer) { 'sidebar' }

    it 'matches issue_sidebar json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar', dir: 'ee')
    end
  end

  context 'sidebar extras issue serialization' do
    let(:serializer) { 'sidebar_extras' }

    it 'matches issue_sidebar_extras json schema' do
      expect(json_entity).to match_schema('entities/issue_sidebar_extras', dir: 'ee')
    end
  end
end
