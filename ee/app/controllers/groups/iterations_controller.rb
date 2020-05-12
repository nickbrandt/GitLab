# frozen_string_literal: true

class Groups::IterationsController < Groups::ApplicationController
  before_action :check_iterations_available!
  before_action :authorize_show_iteration!, only: :show
  before_action :authorize_create_iteration!, only: [:new, :create]

  def index; end

  def new
    @iteration = Sprint.new
  end

  def create
    @iteration = Iterations::CreateService.new(group, current_user, iteration_params).execute

    if @iteration.success?
      redirect_to iteration_path
    else
      render "new"
    end
  end

  def show
  end

  private

  def iteration_params
    params.require(:sprint).permit(:title, :description, :start_date, :due_date)
  end

  def check_iterations_available!
    return render_404 unless group.feature_available?(:iterations)
  end

  def authorize_create_iteration!
    return render_404 unless can?(current_user, :create_iteration, group)
  end

  def authorize_show_iteration!
    return render_404 unless can?(current_user, :read_iteration, group)
  end
end
