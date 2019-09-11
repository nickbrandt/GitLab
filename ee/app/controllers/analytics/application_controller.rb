# frozen_string_literal: true

class Analytics::ApplicationController < ApplicationController
  include RoutableActions

  layout 'analytics'

  private

  def self.check_feature_flag(flag, *args)
    before_action(*args) { render_404 unless Feature.enabled?(flag) }
  end

  private_class_method :check_feature_flag
end
