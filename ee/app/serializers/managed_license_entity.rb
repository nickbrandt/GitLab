# frozen_string_literal: true

class ManagedLicenseEntity < Grape::Entity
  expose :id
  expose :classification, as: :approval_status
  expose :software_license, merge: true do
    expose :name
  end
end
