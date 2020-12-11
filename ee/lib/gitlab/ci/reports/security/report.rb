# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :created_at, :type, :pipeline, :findings, :scanners, :identifiers
          attr_accessor :scan, :scanned_resources, :error

          def initialize(type, pipeline, created_at)
            @type = type
            @pipeline = pipeline
            @created_at = created_at
            @findings = []
            @scanners = {}
            @identifiers = {}
            @scanned_resources = []
          end

          def commit_sha
            pipeline.sha
          end

          def errored?
            error.present?
          end

          def add_scanner(scanner)
            scanners[scanner.key] ||= scanner
          end

          def add_identifier(identifier)
            identifiers[identifier.key] ||= identifier
          end

          def add_finding(finding)
            findings << finding
          end

          def clone_as_blank
            Report.new(type, pipeline, created_at)
          end

          def replace_with!(other)
            instance_variables.each do |ivar|
              instance_variable_set(ivar, other.public_send(ivar.to_s[1..-1])) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def merge!(other)
            replace_with!(::Security::MergeReportsService.new(self, other).execute)
          end

          def primary_scanner
            scanners.first&.second
          end

          # It's important to read the `project_id` attribute instead of calling
          # `project_id` on pipeline. Because the `Ci::Pipeline` delegates the `project_id`
          # call to the `project` relation even though it already has the attribute called
          # `project_id`. By reading attribute directly from the entity, we are preventing
          # an extra database query to load the project.
          def project_id
            pipeline&.read_attribute(:project_id)
          end
        end
      end
    end
  end
end
