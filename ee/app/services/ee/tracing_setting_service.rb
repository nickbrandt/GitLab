# frozen_string_literal: true

module EE
  class TracingSettingService < BaseService
    ValidationError = Class.new(StandardError)

    def execute
      # Convert an empty string in tracing_external_url to nil
      if params.has_key?(:external_url)
        params[:external_url] = params[:external_url].presence
      end

      # Delete the row in project_tracing_settings table if external_row is to be
      # set to nil since that is currently the only value in the table.
      if params[:external_url].nil?
        destroy
      else
        create_or_update
      end
    rescue ValidationError => e
      error(e.message)
    end

    def create_or_update
      if ProjectTracingSetting.create_or_update(project, params)
        success
      else
        update_failed
      end
    end

    def destroy
      tracing_setting = ProjectTracingSetting.for_project(project)

      if tracing_setting.persisted? && tracing_setting.destroy
        success
      else
        destroy_failed
      end
    end

    def update_failed
      model_errors = project.errors.full_messages.to_sentence
      error_message = model_errors.presence || 'Project tracing settings could not be updated!'

      error(error_message)
    end

    def destroy_failed
      model_errors = project.errors.full_messages.to_sentence
      error_message = model_errors.presence || 'Project tracing settings could not be deleted!'

      error(error_message)
    end
  end
end
