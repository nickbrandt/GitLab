# frozen_string_literal: true

FactoryBot.modify do
  factory :upload do
    trait :design_action_image_v432x230_upload do
      mount_point { :image_v432x230 }
      model { create(:design_action) }
      uploader { ::DesignManagement::DesignV432x230Uploader.name }
    end
  end
end
