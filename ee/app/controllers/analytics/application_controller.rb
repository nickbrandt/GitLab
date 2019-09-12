# frozen_string_literal: true

class Analytics::ApplicationController < ApplicationController
  include RoutableActions

  layout 'analytics'

  private

  def self.check_feature_flag(flag, *args)
    before_action(*args) { render_404 unless Feature.enabled?(flag) }
  end

  def self.increment_usage_counter(counter_klass, counter, *args)
    before_action(*args) { counter_klass.count(counter) }
  end

  private_class_method :check_feature_flag, :increment_usage_counter
end
