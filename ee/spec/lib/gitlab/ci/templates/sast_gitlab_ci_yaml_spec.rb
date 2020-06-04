# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SAST.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('SAST') }

  describe 'the created pipeline' do
    let(:user) { create(:admin) }
    let(:default_branch) { 'master' }
    let(:files) { { 'README.txt' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
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

      context 'when SAST_DISABLE_DIND=false' do
        before do
          create(:ci_variable, project: project, key: 'SAST_DISABLE_DIND', value: 'false')
        end

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

      context 'by default' do
        describe 'language detection' do
          using RSpec::Parameterized::TableSyntax

          where(:case_name, :files, :variables, :include_build_names) do
            'No match'             | { 'README.md' => '' }                | {}                                        | %w(secrets-sast)
            'Apex'                 | { 'app.cls' => '' }                  | {}                                        | %w(pmd-apex-sast secrets-sast)
            'C'                    | { 'app.c' => '' }                    | {}                                        | %w(flawfinder-sast secrets-sast)
            'C++'                  | { 'app.cpp' => '' }                  | {}                                        | %w(flawfinder-sast secrets-sast)
            'C#'                   | { 'app.csproj' => '' }               | {}                                        | %w(security-code-scan-sast secrets-sast)
            'Elixir'               | { 'mix.exs' => '' }                  | {}                                        | %w(sobelow-sast secrets-sast)
            'Golang'               | { 'main.go' => '' }                  | {}                                        | %w(gosec-sast secrets-sast)
            'Groovy'               | { 'app.groovy' => '' }               | {}                                        | %w(spotbugs-sast secrets-sast)
            'Java'                 | { 'app.java' => '' }                 | {}                                        | %w(spotbugs-sast secrets-sast)
            'Javascript'           | { 'app.js' => '' }                   | {}                                        | %w(eslint-sast secrets-sast)
            'Javascript Node'      | { 'package.json' => '' }             | {}                                        | %w(nodejs-scan-sast secrets-sast)
            'HTML'                 | { 'index.html' => '' }               | {}                                        | %w(eslint-sast secrets-sast)
            'Kubernetes Manifests' | { 'Chart.yaml' => '' }               | { 'SCAN_KUBERNETES_MANIFESTS' => 'true' } | %w(kubesec-sast secrets-sast)
            'Multiple languages'   | { 'app.java' => '', 'app.js' => '' } | {}                                        | %w(eslint-sast spotbugs-sast secrets-sast)
            'PHP'                  | { 'app.php' => '' }                  | {}                                        | %w(phpcs-security-audit-sast secrets-sast)
            'Python'               | { 'app.py' => '' }                   | {}                                        | %w(bandit-sast secrets-sast)
            'Ruby'                 | { 'config/routes.rb' => '' }         | {}                                        | %w(brakeman-sast secrets-sast)
            'Scala'                | { 'app.scala' => '' }                | {}                                        | %w(spotbugs-sast secrets-sast)
            'Typescript'           | { 'app.ts' => '' }                   | {}                                        | %w(tslint-sast secrets-sast)
            'Visual Basic'         | { 'app.vbproj' => '' }               | {}                                        | %w(security-code-scan-sast secrets-sast)
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
