# frozen_string_literal: true

class DependencyProxy::FileUploader < GitlabUploader
  include ObjectStorage::Concern

  storage_options Gitlab.config.dependency_proxy

  alias_method :upload, :model

  def filename
    model.file_name
  end

  def store_dir
    dynamic_segment
  end

  private

  def dynamic_segment
    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              'dependency_proxy', model.group_id.to_s, 'files', model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.group_id.to_s)
  end
end
