# frozen_string_literal: true

FactoryBot.modify do
  factory :upload do
    trait :design_action_upload do
      mount_point { :file }
      model { create(:design_action) }
      uploader { ::DesignManagement::DesignUploader.name }
    end
  end
end
