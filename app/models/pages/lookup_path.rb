# frozen_string_literal: true

module Pages
  class LookupPath
    def initialize(project, trim_prefix: nil, domain: nil)
      @project = project
      @domain = domain
      @trim_prefix = trim_prefix || project.full_path
    end

    def project_id
      project.id
    end

    def access_control
      project.private_pages?
    end

    def https_only
      domain_https = domain ? domain.https? : true
      project.pages_https_only? && domain_https
    end

    def source
      if artifacts_archive
        zip_sourse
      else
        legacy_file_source
      end
    end

    def prefix
      if project.pages_group_root?
        '/'
      else
        project.full_path.delete_prefix(trim_prefix) + '/'
      end
    end

    private

    attr_reader :project, :trim_prefix, :domain

    def artifacts_archive
      @artifacts_archive ||=
        begin
          build = project.builds.where(name: 'pages', status: 'success').last
          build.artifacts_file_for_type(:archive)
        end
    end

    def zip_sourse
      {
        type: 'zip',
        path: artifacts_archive.url
      }
    end

    def legacy_file_source
      {
        type: 'file',
        path: File.join(project.full_path, 'public/')
      }
    end
  end
end
