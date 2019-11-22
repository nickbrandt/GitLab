# frozen_string_literal: true

require 'securerandom'

module Clusters
  module Applications
    class Sentry < ApplicationRecord
      VERSION = '3.1.1'
      DEFAULT_USER_EMAIL = 'sentry@gitlab.com'
      DEFAULT_USER_PASSWORD = '5iveL!fe'

      self.table_name = 'clusters_applications_sentry'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationVersion
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      def set_initial_status
        return unless not_installable?
        return unless cluster&.application_ingress_available?

        ingress = cluster.application_ingress
        self.status = status_states[:installable] if ingress.external_ip_or_hostname?
      end

      def chart
        "stable/sentry"
      end

      def values
        content_values.to_yaml
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name: name,
          version: VERSION,
          rbac: cluster.platform_kubernetes_rbac?,
          chart: chart,
          files: files,
          repository: repository
        )
      end

      private

      def specification
        {
          "ingress" => {
            "enabled" => true,
            "hostname" => hostname,
            "annotations" => {
              "kubernetes.io/ingress.class" => "nginx"
            }
          },
          "service" => {
            "type" => "ClusterIP"
          },
          "user" => {
            "email" => DEFAULT_USER_EMAIL,
            "password" => DEFAULT_USER_PASSWORD
          }
        }
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end
    end
  end
end
