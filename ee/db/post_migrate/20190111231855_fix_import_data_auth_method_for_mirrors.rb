# frozen_string_literal: true

class FixImportDataAuthMethodForMirrors < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_one :import_data, class_name: '::FixImportDataAuthMethodForMirrors::ProjectImportData', inverse_of: :project
  end

  class ProjectImportData < ActiveRecord::Base
    self.table_name = 'project_import_data'

    belongs_to :project, inverse_of: :import_data

    attr_encrypted :credentials,
                   key: Settings.attr_encrypted_db_key_base,
                   marshal: true,
                   encode: true,
                   mode: :per_attribute_iv_and_salt,
                   insecure_mode: true,
                   algorithm: 'aes-256-cbc'

    serialize :data, JSON

    def auth_method
      auth_method = credentials.fetch(:auth_method, nil) if credentials.present?

      auth_method.presence || 'password'
    end

    def auth_method=(value)
      creds = self.credentials || {}
      creds[:auth_method] = value
      # For some reason, we need to reassign it back to attr_encrypted
      # for changes to take effect.
      self.credentials = creds
    end
  end

  def up
    # There are about 60,000 project mirrors that match this criteria on GitLab.com.
    # Only 129 had this issue, so most of the time will be spent decrypting secrets.
    # It took about 3 minutes to complete.
    Project.where(mirror: true).where("import_url LIKE 'http%'").preload(:import_data).find_each do |project|
      begin
        import_data = project.import_data

        next unless import_data

        if import_data.auth_method == 'ssh_public_key'
          import_data.auth_method = 'password'
          import_data.save
        end
      rescue OpenSSL::Cipher::CipherError
        Rails.logger.warn "Error decrypting credentials in import data #{import_data&.id}"
      end
    end
  end
end
