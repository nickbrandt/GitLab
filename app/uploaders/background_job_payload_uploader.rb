# frozen_string_literal: true

class BackgroundJobPayloadUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_options Gitlab.config.background_job_payloads

  alias_method :upload, :model

  def filename
    "#{model[:jid]}-payload.json"
  end

  def store_dir
    dynamic_segment
  end

  def move_to_store
    false
  end

  def move_to_cache
    false
  end

  def save!
    tmp = Tempfile.new(filename)
    File.open(tmp.path, "w") { |f| f.write model[:args] }
    file = {
      tempfile:     tmp,
      filename:     filename,
      content_type: 'application/json'
    }
    store!(file)

    true
  end

  def load!
    retrieve_from_store!(filename)
    file.read
  end

  def object_store
    ObjectStorage::Store::REMOTE
  end

  private

  def dynamic_segment
    model[:class]
  end
end
