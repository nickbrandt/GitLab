# frozen_string_literal: true

module QA
  module Runtime
    class AllureReport
      class << self
        # Configure allure reports
        #
        # @return [void]
        def configure!
          return unless Env.generate_allure_report?

          require 'allure-rspec'

          configure_allure
          configure_attachments
          configure_rspec
        end

        private

        # Configure allure reporter
        #
        # @return [void]
        def configure_allure
          # Match job names like ee:relative, ce:update etc. and set as execution environment
          env_matcher = /^(?<env>\w{2}:\S+)/

          AllureRspec.configure do |config|
            config.results_directory = 'tmp/allure-results'
            config.clean_results_directory = true

            # Set custom environment name to separate same specs executed on different environments
            if Env.running_in_ci? && Env.ci_job_name.match?(env_matcher)
              config.environment = Env.ci_job_name.match(env_matcher).named_captures['env']
            end
          end
        end

        # Set up failure screenshot attachments
        #
        # @return [void]
        def configure_attachments
          Capybara::Screenshot.after_save_screenshot do |path|
            Allure.add_attachment(
              name: 'screenshot',
              source: File.open(path),
              type: Allure::ContentType::PNG,
              test_case: true
            )
          end
          Capybara::Screenshot.after_save_html do |path|
            Allure.add_attachment(
              name: 'html',
              source: File.open(path),
              type: 'text/html',
              test_case: true
            )
          end
        end

        # Configure rspec
        #
        # @return [void]
        def configure_rspec
          RSpec.configure do |config|
            config.formatter = AllureRspecFormatter

            config.before do |example|
              next if example.attempts && example.attempts > 0

              testcase = example.metadata[:testcase]
              example.tms('Testcase', testcase) if testcase

              quarantine_issue = example.metadata.dig(:quarantine, :issue)
              example.issue('Quarantine issue', quarantine_issue) if quarantine_issue

              spec_file = example.file_path.split('/').last
              example.issue(
                'Failure issues',
                "https://gitlab.com/gitlab-org/gitlab/-/issues?scope=all&state=opened&search=#{spec_file}"
              )

              example.add_link(name: "Job(#{Env.ci_job_name})", url: Env.ci_job_url) if Env.running_in_ci?
            end
          end
        end
      end
    end
  end
end
