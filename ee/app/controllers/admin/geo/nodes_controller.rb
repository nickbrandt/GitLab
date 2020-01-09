# frozen_string_literal: true

class Admin::Geo::NodesController < Admin::Geo::ApplicationController
  before_action :check_license!, except: :index
  before_action :load_node, only: [:edit, :update]

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @nodes = GeoNode.all.order(:id)
    @node = GeoNode.new

    unless Gitlab::Geo.license_allows?
      flash.now[:alert] = _('You need a different license to use Geo replication.')
    end

    unless Gitlab::Database.postgresql_minimum_supported_version?
      flash.now[:warning] = _('Please upgrade PostgreSQL to version 9.6 or greater. The status of the replication cannot be determined reliably with the current version.')
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def create
    @node = ::Geo::NodeCreateService.new(geo_node_params).execute

    if @node.persisted?
      redirect_to admin_geo_nodes_path, notice: _('Node was successfully created.')
    else
      @nodes = GeoNode.all

      render :new
    end
  end

  def new
    @node = GeoNode.new
  end

  def update
    if ::Geo::NodeUpdateService.new(@node, geo_node_params).execute
      redirect_to admin_geo_nodes_path, notice: _('Node was successfully updated.')
    else
      render :edit
    end
  end

  private

  def geo_node_params
    params.require(:geo_node).permit(
      :name,
      :url,
      :internal_url,
      :primary,
      :selective_sync_type,
      :namespace_ids,
      :repos_max_capacity,
      :files_max_capacity,
      :verification_max_capacity,
      :minimum_reverification_interval,
      :container_repositories_max_capacity,
      :sync_object_storage,
      selective_sync_shards: []
    )
  end

  def load_node
    @node = GeoNode.find(params[:id])
  end
end
