# frozen_string_literal: true

Rails.application.config.middleware.insert_after(ActionDispatch::RequestId, Labkit::Middleware::Rack)
