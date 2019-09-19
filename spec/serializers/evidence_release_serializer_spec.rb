# frozen_string_literal: true

require 'spec_helper'

describe EvidenceReleaseSerializer do
  it 'represents an EvidenceReleaseEntity entity' do
    expect(described_class.entity_class).to eq(EvidenceReleaseEntity)
  end
end
