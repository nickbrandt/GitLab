module Ci
  class BuildArtifactPresenter < Gitlab::View::Presenter::Delegated
    def name      
      return "#{job.name}:#{archive_name}:#{file_type}" if file_type == 'archive'

      "#{job.name}:#{file_type}"
    end

    private

    def archive_name
      # To differentiate multiple archives the file name from the database is used or an index
      # file_in_database corresponds to `artifact:archives:name` in gitlab-ci.yml
      return "#{file_in_database}".split('.').first unless file_in_database == 'artifacts.zip' || file_in_database.nil?

      "artifact#{display_index}"
    end
  end
end
