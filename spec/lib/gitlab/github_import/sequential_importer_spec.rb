# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::SequentialImporter do
  describe '#execute' do
    let(:repository) { double(:repository) }
    let(:importer) { described_class.new(project, token: 'foo') }

    shared_examples 'conduct import' do
      it 'imports a project in sequence' do
        expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
          expect(instance).to receive(:execute)
        end

        described_class::SEQUENTIAL_IMPORTERS.each do |klass|
          instance = double(:instance)

          expect(klass).to receive(:new)
            .with(project, importer.client)
            .and_return(instance)

          expect(instance).to receive(:execute)
        end

        described_class::PARALLEL_IMPORTERS.each do |klass|
          instance = double(:instance)

          expect(klass).to receive(:new)
            .with(project, importer.client, parallel: false)
            .and_return(instance)

          expect(instance).to receive(:execute)
        end

        expect(importer.execute).to eq(true)
      end
    end

    context 'github.com' do
      let(:project) { double(:project, id: 1, repository: repository, import_url: 'http://t0ken@github.com/repo-org/repo.git') }

      include_examples 'conduct import'
    end

    context 'GitHub Enterprise' do
      let(:project) { double(:project, id: 1, repository: repository, import_url: 'http://t0ken@github.company.com/repo-org/repo.git') }

      include_examples 'conduct import'
    end
  end
end
