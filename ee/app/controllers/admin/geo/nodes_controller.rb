# frozen_string_literal: true

class Admin::Geo::NodesController < Admin::ApplicationController
  before_action :check_license, except: :index
  before_action :load_node, only: [:edit, :update]

  helper EE::GeoHelper

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @nodes = GeoNode.all.order(:id)
    @node = GeoNode.new

    unless Gitlab::Geo.license_allows?
      flash.now[:alert] = _('You need a different license to enable Geo replication.')
    end

    unless Gitlab::Database.pg_stat_wal_receiver_supported?
      flash.now[:warning] = _('Please upgrade PostgreSQL to version 9.6 or greater. The status of the replication cannot be determined reliably with the current version.')
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def create
    @node = ::Geo::NodeCreateService.new(geo_node_params).execute

    if @node.persisted?
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully created.'
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
      redirect_to admin_geo_nodes_path, notice: 'Node was successfully updated.'
    else
      render :edit
    end
  end

  private

  def geo_node_params
    params.require(:geo_node).permit(
      :url,
      :primary,
      :selective_sync_type,
      :namespace_ids,
      :repos_max_capacity,
      :files_max_capacity,
      :verification_max_capacity,
      :minimum_reverification_interval,
      selective_sync_shards: []
    )
  end

  def check_license
    unless Gitlab::Geo.license_allows?
      flash[:alert] = 'You need a different license to enable Geo replication'
      redirect_to admin_license_path
    end
  end

  def load_node
    @node = GeoNode.find(params[:id])
  end
end
