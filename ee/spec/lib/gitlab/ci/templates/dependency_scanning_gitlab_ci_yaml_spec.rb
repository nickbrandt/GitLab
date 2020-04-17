# frozen_string_literal: true

require 'spec_helper'

describe 'Dependency-Scanning.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('Dependency-Scanning') }

  describe 'the created pipeline' do
    let(:user) { create(:admin) }
    let(:default_branch) { 'master' }
    let(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: 'master' ) }
    let(:pipeline) { service.execute!(:push) }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      it 'includes no jobs' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
      end
    end

    context 'when project has Ultimate license' do
      let(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'by default' do
        it 'includes orchestrator job' do
          expect(build_names).to match_array(%w[dependency_scanning])
        end
      end

      context 'when DEPENDENCY_SCANNING_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'DEPENDENCY_SCANNING_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end

      context 'when DS_DISABLE_DIND=1' do
        before do
          create(:ci_variable, project: project, key: 'DS_DISABLE_DIND', value: '1')
        end

        describe 'language detection' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :variables, :include_build_names) do
            'Go'                   | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "go" }              | %w(gemnasium-dependency_scanning)
            'Java'                 | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "java" }            | %w(gemnasium-maven-dependency_scanning)
            'Javascript'           | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "javascript" }      | %w(gemnasium-dependency_scanning retire-js-dependency_scanning)
            'Multiple languages'   | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "java,javascript" } | %w(gemnasium-dependency_scanning gemnasium-maven-dependency_scanning retire-js-dependency_scanning)
            'PHP'                  | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "php" }             | %w(gemnasium-dependency_scanning)
            'Python'               | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "python" }          | %w(gemnasium-python-dependency_scanning)
            'Ruby'                 | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "ruby" }            | %w(bundler-audit-dependency_scanning gemnasium-dependency_scanning)
            'Scala'                | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "scala" }           | %w(gemnasium-maven-dependency_scanning)
          end

          with_them do
            before do
              variables.each do |(key, value)|
                create(:ci_variable, project: project, key: key, value: value)
              end
            end

            it 'creates a pipeline with the expected jobs' do
              expect(build_names).to include(*include_build_names)
            end
          end
        end
      end
    end
  end
end
