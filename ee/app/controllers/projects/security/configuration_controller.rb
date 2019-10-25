# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationController < Projects::ApplicationController
      def show
        head :ok
      end
    end
  end
end
