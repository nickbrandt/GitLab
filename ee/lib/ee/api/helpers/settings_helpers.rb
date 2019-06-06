# frozen_string_literal: true

module EE
  module API
    module Helpers
      module SettingsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :elasticsearch_aws, type: Grape::API::Boolean, desc: 'Enable support for AWS hosted elasticsearch'

            given elasticsearch_aws: ->(val) { val } do
              optional :elasticsearch_aws_access_key, type: String, desc: 'AWS IAM access key'
              requires :elasticsearch_aws_region, type: String, desc: 'The AWS region the elasticsearch domain is configured'
              optional :elasticsearch_aws_secret_access_key, type: String, desc: 'AWS IAM secret access key'
            end

            optional :elasticsearch_indexing, type: Grape::API::Boolean, desc: 'Enable Elasticsearch indexing'

            given elasticsearch_indexing: ->(val) { val } do
              optional :elasticsearch_search, type: Grape::API::Boolean, desc: 'Enable Elasticsearch search'
              requires :elasticsearch_url, type: String, desc: 'The url to use for connecting to Elasticsearch. Use a comma-separated list to support clustering (e.g., "http://localhost:9200, http://localhost:9201")'
              optional :elasticsearch_limit_indexing, type: Grape::API::Boolean, desc: 'Limit Elasticsearch to index certain namespaces and projects'
            end

            given elasticsearch_limit_indexing: ->(val) { val } do
              optional :elasticsearch_namespace_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::LabelsList.coerce, desc: 'The namespace ids to index with Elasticsearch.'
              optional :elasticsearch_project_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::LabelsList.coerce, desc: 'The project ids to index with Elasticsearch.'
            end

            optional :email_additional_text, type: String, desc: 'Additional text added to the bottom of every email for legal/auditing/compliance reasons'
            optional :default_project_deletion_protection, type: Grape::API::Boolean, desc: 'Disable project owners ability to delete project'
            optional :help_text, type: String, desc: 'GitLab server administrator information'
            optional :repository_size_limit, type: Integer, desc: 'Size limit per repository (MB)'
            optional :file_template_project_id, type: Integer, desc: 'ID of project where instance-level file templates are stored.'
            optional :repository_storages, type: Array[String], desc: 'A list of names of enabled storage paths, taken from `gitlab.yml`. New projects will be created in one of these stores, chosen at random.'
            optional :snowplow_enabled, type: Grape::API::Boolean, desc: 'Enable Snowplow'

            given snowplow_enabled: ->(val) { val } do
              requires :snowplow_collector_uri, type: String, desc: 'Snowplow Collector URI'
              optional :snowplow_cookie_domain, type: String, desc: 'Snowplow cookie domain'
              optional :snowplow_site_id, type: String, desc: 'Snowplow Site/Application ID'
            end

            optional :usage_ping_enabled, type: Grape::API::Boolean, desc: 'Every week GitLab will report license usage back to GitLab, Inc.'
          end
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :optional_attributes
          def optional_attributes
            super + EE::ApplicationSettingsHelper.possible_licensed_attributes
          end
        end
      end
    end
  end
end
