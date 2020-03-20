# frozen_string_literal: true

module Groups
  module Settings
    class IntegrationsController < Groups::ApplicationController
      include ServiceParams

      before_action :not_found, unless: :group_level_integrations_enabled?
      before_action :authorize_admin_group!
      before_action :service, only: [:edit, :update, :test]

      def edit
      end

      def update
        @service.attributes = service_params[:service]

        saved = @service.save(context: :manual_change)

        respond_to do |format|
          format.html do
            if saved
              redirect_to edit_group_settings_integration_path(@group, @service), notice: success_message
            else
              render :edit
            end
          end

          format.json do
            status = saved ? :ok : :unprocessable_entity

            render json: serialize_as_json, status: status
          end
        end
      end

      def test
        if @service.can_test?
          render json: service_test_response, status: :ok
        else
          render json: {}, status: :not_found
        end
      end

      private

      def group_level_integrations_enabled?
        Feature.enabled?(:group_level_integrations)
      end

      def project
        # TODO: Change to something more meaningful
        Project.first
      end

      def service
        @service ||= project.find_or_initialize_service(params[:id])
      end

      def success_message
        message = @service.active? ? _('activated') : _('settings saved, but not activated')

        _('%{service_title} %{message}.') % { service_title: @service.title, message: message }
      end

      def serialize_as_json
        @service
          .as_json(only: @service.json_fields)
          .merge(errors: @service.errors.as_json)
      end

      def service_test_response
        unless @service.update(service_params[:service])
          return { error: true, message: _('Validations failed.'), service_response: @service.errors.full_messages.join(','), test_failed: false }
        end

        data = @service.test_data(project, current_user)
        outcome = @service.test(data)

        unless outcome[:success]
          return { error: true, message: _('Test failed.'), service_response: outcome[:result].to_s, test_failed: true }
        end

        {}
      rescue Gitlab::HTTP::BlockedUrlError => e
        { error: true, message: _('Test failed.'), service_response: e.message, test_failed: true }
      end
    end
  end
end
