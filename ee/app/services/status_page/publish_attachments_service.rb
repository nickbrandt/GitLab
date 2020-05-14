# frozen_string_literal: true

module StatusPage
  class PublishAttachmentsService < PublishBaseService
    private

    def process(issue, user_notes)
      total_uploads = existing_keys(issue).size
      publish_description_attachments(issue, total_uploads)
      publish_user_note_attachments(issue, total_uploads, user_notes)

      success
    end

    def publish_description_attachments(issue, total_uploads)
      publish_markdown_uploads(
        markdown_field: issue.description,
        issue_iid: issue.iid,
        total_uploads: total_uploads
      )
    end

    def publish_user_note_attachments(issue, total_uploads, user_notes)
      user_notes.each do |user_note|
        publish_markdown_uploads(
          markdown_field: user_note.note,
          issue_iid: issue.iid,
          total_uploads: total_uploads
        )
      end
    end

    def existing_keys(issue = nil)
      strong_memoize(:existing_keys) do
        storage_client.list_object_keys(
          uploads_path(issue)
        )
      end
    end

    def uploads_path(issue)
      StatusPage::Storage.uploads_path(issue.iid)
    end

    def publish_markdown_uploads(markdown_field:, issue_iid:, total_uploads:)
      markdown_field.scan(FileUploader::MARKDOWN_PATTERN).map do |secret, file_name|
        break if total_uploads >= StatusPage::Storage::MAX_IMAGE_UPLOADS

        key = StatusPage::Storage.upload_path(issue_iid, secret, file_name)

        next if existing_keys.include? key

        uploader = UploaderFinder.new(@project, secret, file_name).execute
        uploader.open do |open_file|
          storage_client.multipart_upload(key, open_file)
          total_uploads += 1
        end
      end
    end
  end
end
