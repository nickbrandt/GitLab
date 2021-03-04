# frozen_string_literal: true

class UserCalloutsController < ApplicationController
  feature_category :navigation

  def create
    callout = current_user.find_or_initialize_callout(feature_name)
    callout.update(dismissed_at: Time.current) if callout.valid?

    if callout.persisted?
      respond_to do |format|
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.json { head :bad_request }
      end
    end
  end

  private

  def feature_name
    params.require(:feature_name)
  end
end
