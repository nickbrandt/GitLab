# frozen_string_literal: true

module Packages
  module Helm
    class GenerateIndexService
      def initialize(project, channel)
        @project = project
        @channel = channel
      end

      def execute
        entries = Hash.new { |h, k| h[k] = [] }

        package_files = Packages::Helm::PackageFilesFinder.new(
          @project,
          @channel,
          order_by: 'created_at',
          sort: 'desc',
          limit: 1000
        ).execute.preload_helm_file_metadata

        package_files.find_each do |package_file|
          name = package_file.helm_metadata['name']
          entries[name] << package_file.helm_metadata.merge({
            'created' => package_file.created_at.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'),
            'digest' => package_file.file_sha256,
            'urls' => ["charts/#{package_file.file_name}"]
          })
        end

        {
          'apiVersion' => 'v1',
          'entries' => entries,
          'generated' => Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ')
        }
      end
    end
  end
end
