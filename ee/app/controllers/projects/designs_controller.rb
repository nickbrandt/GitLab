# frozen_string_literal: true

class Projects::DesignsController < Projects::ApplicationController
  include SendsBlob

  before_action :authorize_read_design!

  def show
    blob = design_repository.blob_at(ref, design.full_path)

    send_blob(design_repository, blob, { inline: false })
  end

  private

  def ref
    @ref ||= params[:ref] || design_repository.root_ref
  end

  def design
    @design ||= project.designs.find(params[:id])
  end

  def design_repository
    @design_repository ||= @project.design_repository
  end

  def authorize_read_design!
    unless can?(current_user, :read_design, design)
      access_denied!
    end
  end
end
