# frozen_string_literal: true

require 'spec_helper'

describe DependencyListEntity do
  describe '#as_json' do
    let(:entity) do
      described_class.represent(dependencies, build: build, request: request)
    end

    let(:request) { double('request') }
    set(:project) { create(:project, :public, :builds_private) }
    set(:developer) { create(:user) }

    subject { entity.as_json }

    before do
      project.add_developer(developer)
      allow(request).to receive(:project).and_return(project)
      allow(request).to receive(:current_user).and_return(user)
    end

    context 'with success build' do

      let(:user) { developer }
      let(:build) { create(:ee_ci_build, :success) }

      context 'with provided dependencies' do
        let(:dependencies) do
          [{
             name:     'nokogiri',
             packager: 'Ruby (Bundler)',
             version:  '1.8.0',
             location: {
               blob_path: '/some_project/path/Gemfile.lock',
               path:      'Gemfile.lock'
             }
           }]
        end

        it 'has array of dependencies with status ok' do
          job_path = "/#{project.full_path}/builds/#{build.id}"

          expect(subject[:dependencies][0][:name]).to eq('nokogiri')
          expect(subject[:report][:status]).to eq(:ok)
          expect(subject[:report][:job_path]).to eq(job_path)
        end
      end

      context 'with no dependencies' do
        let(:user) { developer }
        let(:dependencies) { [] }

        it 'has empty array of dependencies with status no_dependencies' do
          job_path = "/#{project.full_path}/builds/#{build.id}"

          expect(subject[:dependencies].length).to eq(0)
          expect(subject[:report][:status]).to eq(:no_dependencies)
          expect(subject[:report][:job_path]).to eq(job_path)
        end
      end
    end

    context 'with failed build' do
      let(:build) { create(:ee_ci_build, :failed) }
      let(:dependencies) { [] }

      context 'with authorized user' do
        let(:user) { developer }

        it 'has job_path with status failed_job' do
          expect(subject[:report][:status]).to eq(:job_failed)
          expect(subject[:report]).to include(:job_path)
        end
      end

      context 'without authorized user' do
        let(:user) { create(:user) }

        it 'has only status failed_job' do
          expect(subject[:report][:status]).to eq(:job_failed)
          expect(subject[:report]).not_to include(:job_path)
        end
      end
    end

    context 'with no build' do
      let(:user) { developer }
      let(:build) { nil }
      let(:dependencies) { [] }

      it 'has status job_not_set_up and no job_path' do
        expect(subject[:report][:status]).to eq(:job_not_set_up)
        expect(subject[:report][:job_path]).not_to be_present
      end
    end
  end
end
