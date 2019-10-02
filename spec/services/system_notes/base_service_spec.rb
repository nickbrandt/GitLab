# frozen_string_literal: true

require 'spec_helper'

describe SystemNotes::BaseService do
  let(:noteable) { double }
  let(:project) { double }
  let(:author) { double }

  let(:base_service) { described_class.new(noteable, project, author) }

  describe '#noteable' do
    subject { base_service.noteable }

    it { is_expected.to eq(noteable) }
  end

  describe '#project' do
    subject { base_service.project }

    it { is_expected.to eq(project) }
  end

  describe '#author' do
    subject { base_service.author }

    it { is_expected.to eq(author) }
  end
end
