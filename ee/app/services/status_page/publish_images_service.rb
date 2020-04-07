# frozen_string_literal: true

module StatusPage
  # Parse an issue for images and publish them to CDN.
  #
  # This is an internal service which is part of
  # +StatusPage::PublishService+ and is not meant to be called directly.
  #
  # Consider calling +StatusPage::PublishService+ instead.
  class PublishImagesService < PublishBaseService
    private

    def process(issue)
      issue.description.scan(FileUploader::MARKDOWN_PATTERN).map do
        file = UploadFinder.new(@project, $~[:secret], $~[:file]).execute.file.file

        File.open(file) do |body|
          storage_client.upload_object("uploads/#{$~[:secret]}/#{$~[:file]}", body)
        end

        success
      end
    end
  end
end
