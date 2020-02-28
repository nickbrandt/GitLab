# frozen_string_literal: true

class Admin::Geo::NodesController < Admin::Geo::ApplicationController
  before_action :check_license!, except: :index
  before_action :load_node, only: [:edit, :update]
  before_action :push_feature_flag, except: :index

  # rubocop: disable CodeReuse/ActiveRecord
  def index
    @nodes = GeoNode.all.order(:id)
    @node = GeoNode.new

    unless Gitlab::Database.postgresql_minimum_supported_version?
      flash.now[:warning] = _('Please upgrade PostgreSQL to version 9.6 or greater. The status of the replication cannot be determined reliably with the current version.')
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def create
    @node = ::Geo::NodeCreateService.new(geo_node_params).execute

    if @node.persisted?
      flash[:toast] = _('Node was successfully created.')
      redirect_to admin_geo_nodes_path
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
      flash[:toast] = _('Node was successfully updated.')
      redirect_to admin_geo_nodes_path
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
    @serialized_node = GeoNodeSerializer.new.represent(@node).to_json
  end

  def push_feature_flag
    push_frontend_feature_flag(:enable_geo_node_form_js)
  end
end
