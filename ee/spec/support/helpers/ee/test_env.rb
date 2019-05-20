# frozen_string_literal: true

module EE
  module TestEnv
    def init(*args, &blk)
      super

      setup_indexer
    end

    def setup_indexer
      indexer_args = [indexer_path, indexer_url].compact.join(',')

      component_timed_setup(
        'GitLab Elasticsearch Indexer',
        install_dir: indexer_path,
        version: indexer_version,
        task: "gitlab:indexer:install[#{indexer_args}]"
      )

      ENV['PATH'] = # rubocop:disable RSpec/EnvAssignment
        [indexer_bin_path, ENV['PATH']].join(File::PATH_SEPARATOR)
    end

    def indexer_path
      @indexer_path ||= File.join('tmp', 'tests', 'gitlab-elasticsearch-indexer')
    end

    def indexer_bin_path
      @indexer_bin_path ||= File.join(indexer_path, 'bin')
    end

    def indexer_version
      @indexer_version ||= ::Gitlab::Elastic::Indexer.experimental_indexer_version
    end

    def indexer_url
      ENV.fetch('GITLAB_ELASTICSEARCH_INDEXER_URL', nil)
    end

    private

    def test_dirs
      @ee_test_dirs ||= super + ['gitlab-elasticsearch-indexer']
    end
  end
end
