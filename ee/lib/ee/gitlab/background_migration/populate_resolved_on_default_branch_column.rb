# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module PopulateResolvedOnDefaultBranchColumn
        def perform(*project_ids)
          project_ids.flatten.each { |project_id| PopulateResolvedOnDefaultBranchColumnForProject.perform(project_id) }
        end

        module Routable
          extend ActiveSupport::Concern

          included do
            has_one :route, as: :source
          end

          def full_path
            route&.path || build_full_path
          end

          def build_full_path
            if parent && path
              parent.full_path + '/' + path
            else
              path
            end
          end
        end

        module Visibility
          PUBLIC_LEVEL = 20

          def public?
            visibility_level == PUBLIC_LEVEL
          end
        end

        # This class depends on Gitlab::CurrentSettings
        class Project < ActiveRecord::Base
          include Routable
          include Visibility
          include ::Gitlab::Utils::StrongMemoize

          FILE_TYPES = [5, 6, 7, 8, 21, 23].freeze
          LATEST_PIPELINE_WITH_REPORTS_SQL = <<~SQL
            SELECT
              "ci_pipelines"."id"
            FROM
              "ci_pipelines"
            WHERE
              ci_pipelines.project_id = %{project_id}
              AND ci_pipelines.ref = %{ref}
              AND ci_pipelines.status IN ('success')
              AND (EXISTS (
                SELECT
                  1
                FROM
                  "ci_builds"
                WHERE
                  "ci_builds"."type" = 'Ci::Build'
                  AND ("ci_builds"."retried" IS FALSE OR "ci_builds"."retried" IS NULL)
                  AND (EXISTS (
                    SELECT
                      1
                    FROM
                      "ci_job_artifacts"
                    WHERE
                      (ci_builds.id = ci_job_artifacts.job_id)
                      AND "ci_job_artifacts"."file_type" IN (%{file_types})))
                  AND (ci_pipelines.id = ci_builds.commit_id)))
            ORDER BY
              "ci_pipelines"."id" DESC
            LIMIT 1
          SQL

          belongs_to :namespace
          alias_method :parent, :namespace

          has_one :route, as: :source
          has_many :vulnerabilities
          has_many :vulnerability_findings
          has_many :vulnerability_identifiers
          has_many :vulnerability_scanners

          scope :has_vulnerabilities, -> { joins('INNER JOIN vulnerabilities v ON v.project_id = projects.id').group(:id) }

          def self.polymorphic_name
            'Project'
          end

          def reports
            @reports ||= artifacts.to_a.map(&:reports).flatten
          end

          private

          delegate :connection, to: :'self.class', private: true

          def artifacts
            JobArtifact.for_pipeline(latest_pipeline_id).each { |artifact| artifact.project = self } if latest_pipeline_id
          end

          def latest_pipeline_id
            strong_memoize(:latest_pipeline_id) { pipeline_with_reports&.fetch('id') }
          end

          def pipeline_with_reports
            connection.execute(pipeline_with_reports_sql).first
          end

          def pipeline_with_reports_sql
            format(LATEST_PIPELINE_WITH_REPORTS_SQL, project_id: id, ref: connection.quote(default_branch), file_types: FILE_TYPES.join(', '))
          end

          def default_branch
            @default_branch ||= repository.root_ref || default_branch_from_preferences
          end

          def repository
            @repository ||= Repository.new(full_path, self, shard: repository_storage, disk_path: storage.disk_path)
          end

          def storage
            @storage ||=
              if hashed_repository_storage?
                Storage::Hashed.new(self)
              else
                Storage::LegacyProject.new(self)
              end
          end

          def hashed_repository_storage?
            storage_version.to_i >= 1
          end

          def default_branch_from_preferences
            ::Gitlab::CurrentSettings.default_branch_name if repository.empty?
          end
        end

        module Storage
          class Hashed
            attr_accessor :container

            REPOSITORY_PATH_PREFIX = '@hashed'

            def initialize(container)
              @container = container
            end

            def base_dir
              "#{REPOSITORY_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
            end

            def disk_path
              "#{base_dir}/#{disk_hash}" if disk_hash
            end

            private

            def disk_hash
              @disk_hash ||= Digest::SHA2.hexdigest(container.id.to_s) if container.id
            end
          end

          class LegacyProject
            attr_accessor :project

            def initialize(project)
              @project = project
            end

            def disk_path
              project.full_path
            end
          end
        end

        class Namespace < ActiveRecord::Base
          include Routable
          include Visibility

          belongs_to :parent, class_name: 'Namespace'

          def self.find_sti_class(type_name)
            super("EE::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn::#{type_name}")
          end
        end

        class Group < Namespace
          def self.polymorphic_name
            'Group'
          end
        end

        class JobArtifact < ActiveRecord::Base
          ARTIFACTS_SQL = <<~SQL
            SELECT
              "ci_job_artifacts".*
            FROM "ci_job_artifacts"
            INNER JOIN "ci_builds" ON "ci_job_artifacts"."job_id" = "ci_builds"."id"
              AND "ci_builds"."commit_id" = %{commit_id}
              AND "ci_builds"."type" = 'Ci::Build'
              AND ("ci_builds"."retried" IS FALSE OR "ci_builds"."retried" IS NULL)
            WHERE
              "ci_job_artifacts"."file_type" IN (%{file_types})
          SQL

          FILE_FORMAT_ADAPTERS = {
            gzip: ::Gitlab::Ci::Build::Artifacts::Adapters::GzipStream,
            raw: ::Gitlab::Ci::Build::Artifacts::Adapters::RawStream
          }.freeze

          self.table_name = 'ci_job_artifacts'

          enum file_format: {
            raw: 1,
            zip: 2,
            gzip: 3
          }, _suffix: true

          enum file_location: {
            legacy_path: 1,
            hashed_path: 2
          }

          enum file_type: {
            archive: 1,
            metadata: 2,
            trace: 3,
            junit: 4,
            sast: 5, ## EE-specific
            dependency_scanning: 6, ## EE-specific
            container_scanning: 7, ## EE-specific
            dast: 8, ## EE-specific
            codequality: 9, ## EE-specific
            license_management: 10, ## EE-specific
            license_scanning: 101, ## EE-specific till 13.0
            performance: 11, ## EE-specific till 13.2
            metrics: 12, ## EE-specific
            metrics_referee: 13, ## runner referees
            network_referee: 14, ## runner referees
            lsif: 15, # LSIF data for code navigation
            dotenv: 16,
            cobertura: 17,
            terraform: 18, # Transformed json
            accessibility: 19,
            cluster_applications: 20,
            secret_detection: 21, ## EE-specific
            requirements: 22, ## EE-specific
            coverage_fuzzing: 23, ## EE-specific
            browser_performance: 24, ## EE-specific
            load_performance: 25 ## EE-specific
          }

          mount_uploader :file, JobArtifactUploader

          attr_accessor :project
          delegate :namespace, to: :project

          def self.for_pipeline(pipeline_id)
            find_by_sql(artifacts_sql_for(pipeline_id))
          end

          def self.artifacts_sql_for(pipeline_id)
            format(ARTIFACTS_SQL, commit_id: pipeline_id, file_types: Project::FILE_TYPES.join(', '))
          end

          def reports
            reports = []

            each_blob do |blob|
              report = ::Gitlab::Ci::Reports::Security::Report.new(file_type, nil, created_at)
              parse_security_artifact_blob(report, blob)
              reports << report
            end

            reports
          end

          def hashed_path?
            super || file_location.nil?
          end

          private

          def each_blob(&blk)
            unless file_format_adapter_class
              raise NotSupportedAdapterError, 'This file format requires a dedicated adapter'
            end

            file.open do |stream|
              file_format_adapter_class.new(stream).each_blob(&blk)
            end
          end

          def file_format_adapter_class
            FILE_FORMAT_ADAPTERS[file_format.to_sym]
          end

          def parse_security_artifact_blob(security_report, blob)
            report_clone = security_report.clone_as_blank
            ::Gitlab::Ci::Parsers.fabricate!(security_report.type).parse!(blob, report_clone)
            security_report.merge!(report_clone)
          end
        end

        class Route < ActiveRecord::Base; end
        class Vulnerability < ActiveRecord::Base
          include EachBatch

          scope :id_not_in, -> (ids) { where.not(id: ids) }
        end
        class VulnerabilityFinding < ActiveRecord::Base
          self.table_name = 'vulnerability_occurrences'

          attribute(:project_fingerprint, ::Gitlab::Database::ShaAttribute.new)
          attribute(:location_fingerprint, ::Gitlab::Database::ShaAttribute.new)

          belongs_to :scanner, class_name: 'VulnerabilityScanner'
          belongs_to :primary_identifier, class_name: 'VulnerabilityIdentifier'
        end
        class VulnerabilityScanner < ActiveRecord::Base
          scope :by_external_id, -> (external_ids) { where(external_id: external_ids) }
        end
        class VulnerabilityIdentifier < ActiveRecord::Base
          attribute(:fingerprint, ::Gitlab::Database::ShaAttribute.new)

          scope :by_fingerprint, -> (fingerprints) { where(fingerprint: fingerprints) }
        end

        # This class depends on following classes
        #   GlRepository class defined in `lib/gitlab/gl_repository.rb`
        #   Repository class defined in `lib/gitlab/git/repository.rb`.
        class Repository
          def initialize(full_path, container, shard:, disk_path: nil, repo_type: ::Gitlab::GlRepository::PROJECT)
            @full_path = full_path
            @shard = shard
            @disk_path = disk_path || full_path
            @container = container
            @commit_cache = {}
            @repo_type = repo_type
          end

          def root_ref
            raw_repository&.root_ref
          end

          def empty?
            return true unless exists?

            !has_visible_content?
          end

          private

          attr_reader :full_path, :shard, :disk_path, :container, :repo_type

          delegate :has_visible_content?, to: :raw_repository, private: true

          def exists?
            return false unless full_path

            raw_repository.exists?
          end

          def raw_repository
            return unless full_path

            @raw_repository ||= initialize_raw_repository
          end

          def initialize_raw_repository
            ::Gitlab::Git::Repository.new(shard,
                                        disk_path + '.git',
                                        repo_type.identifier_for_container(container),
                                        container.full_path)
          end
        end

        class PopulateResolvedOnDefaultBranchColumnForProject
          def self.perform(project_id)
            new(project_id).perform
          end

          def initialize(project_id)
            self.project_id = project_id
          end

          def perform
            project.vulnerabilities
                   .id_not_in(existing_vulnerability_ids)
                   .update_all(resolved_on_default_branch: true)
          end

          private

          attr_accessor :project_id

          delegate :reports, to: :project, private: true

          def project
            @project ||= Project.find(project_id)
          end

          def existing_vulnerability_ids
            all_findings_with_scanner.map { |finding| find_saved_finding_for(finding)&.vulnerability_id }.compact
          end

          def all_findings_with_scanner
            reports.flat_map(&:findings).select(&:scanner)
          end

          def find_saved_finding_for(finding)
            project.vulnerability_findings.find_by({
              scanner: scanner_objects[finding.scanner.key],
              primary_identifier: identifier_objects[finding.primary_identifier.key],
              location_fingerprint: finding.location.fingerprint
            })
          end

          def scanner_objects
            @scanner_objects ||= project.vulnerability_scanners.by_external_id(all_scanner_external_ids).group_by(&:external_id)
          end

          def all_scanner_external_ids
            all_scanners.map(&:external_id).uniq
          end

          def all_scanners
            reports.map(&:scanners).flat_map(&:values)
          end

          def identifier_objects
            @identifier_objects ||= project.vulnerability_identifiers.by_fingerprint(all_identifier_fingerprints).group_by(&:fingerprint)
          end

          def all_identifier_fingerprints
            all_identifiers.map(&:fingerprint).uniq
          end

          def all_identifiers
            reports.map(&:identifiers).flat_map(&:values)
          end
        end
      end
    end
  end
end
