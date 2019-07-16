# frozen_string_literal: true

class CycleAnalytics::MedianEntity < Grape::Entity
  include EntityDateHelper

  expose :value

  private

  def value
    object.nil? ? nil : distance_of_time_in_words(object)
  end
end

