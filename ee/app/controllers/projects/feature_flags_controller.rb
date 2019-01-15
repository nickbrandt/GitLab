# frozen_string_literal: true

class Projects::FeatureFlagsController < Projects::ApplicationController
  respond_to :html

  before_action :authorize_read_feature_flag!
  before_action :authorize_create_feature_flag!, only: [:new, :create]
  before_action :authorize_update_feature_flag!, only: [:edit, :update]
  before_action :authorize_destroy_feature_flag!, only: [:destroy]

  before_action :feature_flag, only: [:edit, :update, :destroy]

  def index
    @feature_flags = FeatureFlagsFinder
      .new(project, current_user, scope: params[:scope])
      .execute
      .page(params[:page])
      .per(30)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: { feature_flags: feature_flags_json }.merge(summary_json)
      end
    end
  end

  def new
    @feature_flag = project.operations_feature_flags.new
  end

  def show
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render_success_json
      end
    end
  end

  def create
    @feature_flag = project.operations_feature_flags.create(create_params)

    if @feature_flag.persisted?
      respond_to do |format|
        format.html { redirect_to_index(notice: 'Feature flag was successfully created.') }
        format.json { render_success_json }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render_error_json }
      end
    end
  end

  def edit
  end

  def update
    if feature_flag.update(update_params)
      respond_to do |format|
        format.html { redirect_to_index(notice: 'Feature flag was successfully updated.') }
        format.json { render_success_json }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render_error_json }
      end
    end
  end

  def destroy
    if feature_flag.destroy
      respond_to do |format|
        format.html { redirect_to_index(notice: 'Feature flag was successfully removed.') }
        format.json { render_success_json }
      end
    else
      respond_to do |format|
        format.html { redirect_to_index(alert: 'Feature flag was not removed.') }
        format.json { render_error_json }
      end
    end
  end

  protected

  def feature_flag
    @feature_flag ||= project.operations_feature_flags.find(params[:id])
  end

  def create_params
    params.require(:operations_feature_flag)
          .permit(:name, :description, :active)
  end

  def update_params
    params.require(:operations_feature_flag)
          .permit(:name, :description, :active)
  end

  def feature_flag_json
    FeatureFlagSerializer
      .new(project: @project, current_user: @current_user)
      .represent(feature_flag)
  end

  def feature_flags_json
    FeatureFlagSerializer
      .new(project: @project, current_user: @current_user)
      .with_pagination(request, response)
      .represent(@feature_flags)
  end

  def summary_json
    FeatureFlagSummarySerializer
      .new(project: @project, current_user: @current_user)
      .represent(@project)
  end

  def redirect_to_index(**args)
    redirect_to project_feature_flags_path(@project), status: :found, **args
  end

  def render_success_json
    render json: feature_flag_json, status: :ok
  end

  def render_error_json
    render json: { message: feature_flag.errors.full_messages },
           status: :bad_request
  end
end
