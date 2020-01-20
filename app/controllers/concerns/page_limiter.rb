# frozen_string_literal: true

# Include this in your controller and call `limit_pages` in order
# to configure the limiter.
#
#   Examples:
#     class MyController < ApplicationController
#       include PageLimiter
#
#       before_action only: [:index] do
#         limit_pages(500)
#       end
#
#       # You can override the default response
#       def page_out_of_bounds
#         head :ok
#       end
#
#       # Or provide an entirely different handler:
#       rescue_from PageOutOfBoundsError, with: :something
#

module PageLimiter
  extend ActiveSupport::Concern

  PageLimiterError          = Class.new(StandardError)
  PageLimitNotANumberError  = Class.new(PageLimiterError)
  PageLimitNotSensibleError = Class.new(PageLimiterError)
  PageOutOfBoundsError      = Class.new(PageLimiterError)

  included do
    attr_accessor :max_page_number
    helper_method :max_page_number
    rescue_from PageOutOfBoundsError, with: :page_out_of_bounds
  end

  def limit_pages(number)
    set_max_page_number(number)
    check_page_number
  end

  # Override this method in your controller to customize the response
  def page_out_of_bounds
    default_page_out_of_bounds_response
  end

  private

  def set_max_page_number(value)
    raise PageLimitNotANumberError unless value.is_a?(Integer)
    raise PageLimitNotSensibleError unless value > 0

    self.max_page_number = value
  end

  # If the page exceeds the defined maximum, either call the provided
  # block (if provided) or call the #page_out_of_bounds method to
  # provide a response.
  #
  # If the page doesn't exceed the limit, it yields the controller action.
  def check_page_number
    if params[:page].present? && params[:page].to_i > max_page_number
      record_interception
      raise PageOutOfBoundsError
    end
  end

  # By default just return a HTTP status code and an empty response
  def default_page_out_of_bounds_response
    head :bad_request
  end

  # Record the page limit being hit in Prometheus
  def record_interception
    dd = DeviceDetector.new(request.user_agent)

    Gitlab::Metrics.counter(:gitlab_page_out_of_bounds,
      controller: params[:controller],
      action: params[:action],
      bot: dd.bot?
    )
  end
end
