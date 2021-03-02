# frozen_string_literal: true

class IdeController < ApplicationController
  layout 'fullscreen'

  include ClientsidePreviewCSP
  include StaticObjectExternalStorageCSP

  before_action do
    push_frontend_feature_flag(:build_service_proxy)
    push_frontend_feature_flag(:schema_linting)
  end

  feature_category :web_ide

  def index
    mr = params[:vueroute].match(/merge_requests\/(\d)/)
    if mr.present?
      @merge_request = mr.captures[0]
    end

    branch = params[:vueroute].match(/(?:edit|tree|blob)\/(\S[^\/]*)/)
    if branch.present?
      @branch_name = branch.captures[0]
    end

    file = params[:vueroute].match(/\/-\/(?!$)(\S*)/)
    if file.present?
      @file_path = file.captures[0]
    end

    if mr.present? || branch.present?
      @project = Project.find_by_full_path(params[:vueroute].match(/^project\/(\S*)\/(?:edit|blob|tree|merge_request)/).captures[0])
    else
      @project = Project.find_by_full_path(params[:vueroute].match(/^project\/(.*?)\/?$/).captures[0])
    end

    forks = ForkProjectsFinder.new(@project, current_user: current_user).execute
    if forks.present?
      @forked_project = forks[0]
    end

    Gitlab::UsageDataCounters::WebIdeCounter.increment_views_count
  end
end
