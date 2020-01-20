# frozen_string_literal: true

# Include this in your controller and call `limit_pages` in order
# to configure the limiter.
#
#   Examples:
#     class MyController < ApplicationController
#       include PageLimiter
#       limit_pages 500
#
#       # Optionally provide a block to customize the response:
#       limit_pages 500 do
#         head :ok
#       end
#
#       # Or override the default response method
#       limit_pages 500
#
#       def page_out_of_bounds
#         head :ok
#       end
#

module PageLimiter
  extend ActiveSupport::Concern

  PageLimitNotANumberError = Class.new(StandardError)

  included do
    around_action :check_page_number, if: :max_page_defined?
  end

  class_methods do
    def limit_pages(number, &block)
      set_max_page(number)
      @page_limiter_block = block
    end

    def max_page
      @max_page
    end

    def page_limiter_block
      @page_limiter_block
    end

    private

    def set_max_page(value)
      raise PageLimitNotANumberError unless value.is_a?(Integer)

      @max_page = value
    end
  end

  # Override this method in your controller to customize the response
  def page_out_of_bounds
    default_page_out_of_bounds_response
  end

  private

  # Used to see whether the around_action should run or not
  def max_page_defined?
    self.class.max_page.present? && self.class.max_page > 0
  end

  # If the page exceeds the defined maximum, either call the provided
  # block (if provided) or call the #page_out_of_bounds method to
  # provide a response.
  #
  # If the page doesn't exceed the limit, it yields the controller action.
  def check_page_number
    if params[:page].present? && params[:page].to_i > self.class.max_page
      record_interception

      if self.class.page_limiter_block.present?
        instance_eval(&self.class.page_limiter_block)
      else
        page_out_of_bounds
      end
    else
      yield
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
