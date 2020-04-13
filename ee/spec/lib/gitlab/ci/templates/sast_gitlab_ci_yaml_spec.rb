# frozen_string_literal: true

require 'spec_helper'

describe 'SAST.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('SAST') }

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
          expect(build_names).to match_array(%w[sast])
        end
      end

      context 'when SAST_DISABLED=1' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLED', value: '1')
        end

        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end

      context 'when SAST_DISABLE_DIND=1' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLE_DIND', value: '1')
        end

        describe 'language detection' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :variables, :include_build_names) do
            'No match'             | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "" }                | %w(secrets-sast)
            'Apex'                 | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "apex" }            | %w(pmd-apex-sast secrets-sast)
            'C'                    | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "c" }               | %w(flawfinder-sast secrets-sast)
            'C++'                  | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "c++" }             | %w(flawfinder-sast secrets-sast)
            'C#'                   | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "c#" }              | %w(security-code-scan-sast secrets-sast)
            'Elixir'               | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "elixir" }          | %w(sobelow-sast secrets-sast)
            'Golang'               | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "go" }              | %w(gosec-sast secrets-sast)
            'Groovy'               | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "groovy" }          | %w(spotbugs-sast secrets-sast)
            'Java'                 | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "java" }            | %w(spotbugs-sast secrets-sast)
            'Javascript'           | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "javascript" }      | %w(eslint-sast nodejs-scan-sast secrets-sast)
            'Kubernetes Manifests' | { "SCAN_KUBERNETES_MANIFESTS" => "true" }                  | %w(kubesec-sast secrets-sast)
            'Multiple languages'   | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "java,javascript" } | %w(eslint-sast nodejs-scan-sast spotbugs-sast secrets-sast)
            'PHP'                  | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "php" }             | %w(phpcs-security-audit-sast secrets-sast)
            'Python'               | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "python" }          | %w(bandit-sast secrets-sast)
            'Ruby'                 | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "ruby" }            | %w(brakeman-sast secrets-sast)
            'Scala'                | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "scala" }           | %w(spotbugs-sast secrets-sast)
            'Typescript'           | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "typescript" }      | %w(tslint-sast secrets-sast)
            'Visual Basic'         | { "CI_PROJECT_REPOSITORY_LANGUAGES" => "visual basic" }    | %w(security-code-scan-sast secrets-sast)
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
