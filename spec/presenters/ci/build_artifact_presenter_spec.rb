# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildArtifactPresenter do
  let(:job) { double('Job', name: 'job1') }

  subject(:presenter) { described_class.new(artifact, display_index: 1) }

  describe 'name' do
    context 'when artifact is a named archive' do
      let(:artifact) { double('Artifact', file_in_database: 'success.zip', file_type: 'archive', job: job) }

      it { expect(presenter.name).to eq('job1:success:archive') }
    end

    context 'when artifact is an unnamed archive' do
      let(:artifact) { double('Artifact',  file_in_database: 'artifacts.zip', file_type: 'archive', job: job) }

      it { expect(presenter.name).to eq('job1:artifact1:archive') }
    end

    context 'when artifact is an report' do
      let(:artifact) { double('Artifact',  file_type: 'sast', job: job) }

      it { expect(presenter.name).to eq('job1:sast') }
    end

    context 'when artifact is an file_in_database is nil' do
      let(:artifact) { double('Artifact',  file_in_database: nil, file_type: 'archive', job: job) }

      it { expect(presenter.name).to eq('job1:artifact1:archive') }
    end
  end
end