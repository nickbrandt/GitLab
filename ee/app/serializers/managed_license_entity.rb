# frozen_string_literal: true

class ManagedLicenseEntity < Grape::Entity
  expose :id
  expose :classification, as: :approval_status do |policy|
    SoftwareLicensePolicy::APPROVAL_STATUS.key(policy.classification) ||
      policy.classification
  end
  expose :software_license, merge: true do
    expose :name
  end
end
