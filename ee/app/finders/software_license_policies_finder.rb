# frozen_string_literal: true

class SoftwareLicensePoliciesFinder
  include Gitlab::Allowable
  include FinderMethods

  attr_accessor :current_user, :project

  def initialize(current_user, project, params = {})
    @current_user = current_user
    @project = project
    @params = params
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def execute
    return SoftwareLicensePolicy.none unless can?(current_user, :read_software_license_policy, project)

    items = init_collection

    if license_id
      items.where(id: license_id)
    elsif license_name
      items.with_license_by_name(license_name)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  def find
    execute.take
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  def init_collection
    SoftwareLicensePolicy.with_license.including_license.for_project(@project)
  end

  def license_id
    @params[:name_or_id].to_i if @params[:name_or_id] =~ /\A\d+\Z/
  end

  def license_name
    @params[:name] || @params[:name_or_id]
  end
end
