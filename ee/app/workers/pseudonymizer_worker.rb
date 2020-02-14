# frozen_string_literal: true

class PseudonymizerWorker
  include ApplicationWorker
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :integrations

  def perform
    return unless Gitlab::CurrentSettings.pseudonymizer_enabled?

    options = Pseudonymizer::Options.new(
      config: YAML.load_file(Gitlab.config.pseudonymizer.manifest),
      output_dir: ENV['PSEUDONYMIZER_OUTPUT_DIR']
    )

    dumper = Pseudonymizer::Dumper.new(options)
    uploader = Pseudonymizer::Uploader.new(options, progress_output: File.open(File::NULL, "w"))

    unless uploader.available?
      Rails.logger.error("The pseudonymizer object storage must be configured.") # rubocop:disable Gitlab/RailsLogger
      return
    end

    begin
      dumper.tables_to_csv
      uploader.upload
    ensure
      uploader.cleanup
    end
  end
end
