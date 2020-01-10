# frozen_string_literal: true

class ReviewAppSetupSerializer < BaseSerializer
  entity ReviewAppSetupEntity

  def represent(resource, opts = {}, entity_class = nil)
    super(project_presenter_for(resource), opts, entity_class)
  end

  private

  def project_presenter_for(resource)
    ProjectPresenter.new(resource, current_user: params[:current_user]) # rubocop: disable CodeReuse/Presenter
  end
end
