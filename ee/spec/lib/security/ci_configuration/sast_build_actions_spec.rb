# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastBuildActions do
  context 'autodevops disabled' do
    let(:auto_devops_enabled) { false }

    context 'with no paramaters' do
      let(:params) { {} }

      subject(:result) { described_class.new(auto_devops_enabled, params).generate }

      it 'generates the correct YML' do
        expect(result.first[:content]).to eq(sast_yaml_no_params)
      end
    end

    context 'with all parameters' do
      let(:params) do
        { stage: 'security',
          'SEARCH_MAX_DEPTH' => 1,
          'SECURE_ANALYZERS_PREFIX' => 'localhost:5000/analyzers',
          'SAST_ANALYZER_IMAGE_TAG' => 2,
          'SAST_EXCLUDED_PATHS' => 'docs' }
      end

      subject(:result) { described_class.new(auto_devops_enabled, params).generate }

      it 'generates the correct YML' do
        expect(result.first[:content]).to eq(sast_yaml_all_params)
      end
    end
  end

  context 'with autodevops enabled' do
    let(:auto_devops_enabled) { true }
    let(:params) { { stage: 'custom stage' } }

    subject(:result) { described_class.new(auto_devops_enabled, params).generate }

    it 'generates the correct YML' do
      expect(result.first[:content]).to eq(auto_devops_with_custom_stage)
    end
  end

  def sast_yaml_no_params
    <<-CI_YML.strip_heredoc
    ---
    stages:
    - test
    sast:
      stage: test
      script:
      - "/analyzer run"
    include:
    - template: SAST.gitlab-ci.yml
    # You can override the above template(s) by including variable overrides
    # See https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
    CI_YML
  end

  def sast_yaml_all_params
    <<-CI_YML.strip_heredoc
      ---
      stages:
      - test
      - security
      variables:
        SECURE_ANALYZERS_PREFIX: localhost:5000/analyzers
      sast:
        variables:
          SAST_ANALYZER_IMAGE_TAG: 2
          SAST_EXCLUDED_PATHS: docs
          SEARCH_MAX_DEPTH: 1
        stage: security
        script:
        - "/analyzer run"
      include:
      - template: SAST.gitlab-ci.yml
      # You can override the above template(s) by including variable overrides
      # See https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
    CI_YML
  end

  def auto_devops_with_custom_stage
    <<-CI_YML.strip_heredoc
      ---
      stages:
      - build
      - test
      - deploy
      - review
      - dast
      - staging
      - canary
      - production
      - incremental rollout 10%
      - incremental rollout 25%
      - incremental rollout 50%
      - incremental rollout 100%
      - performance
      - cleanup
      - custom stage
      sast:
        stage: custom stage
        script:
        - "/analyzer run"
      include:
      - template: Auto-DevOps.gitlab-ci.yml
      # You can override the above template(s) by including variable overrides
      # See https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
    CI_YML
  end
end
