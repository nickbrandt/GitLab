# frozen_string_literal: true

class Groups::GroupMembersController < Groups::ApplicationController
  include MembershipActions
  include MembersPresentation
  include SortingHelper
  include Gitlab::Utils::StrongMemoize

  MEMBER_PER_PAGE_LIMIT = 50

  def self.admin_not_required_endpoints
    %i[index leave request_access]
  end

  # Authorize
  before_action :authorize_admin_group_member!, except: admin_not_required_endpoints
  before_action :authorize_read_group_members!, only: %i[index]

  skip_before_action :check_two_factor_requirement, only: :leave
  skip_cross_project_access_check :index, :create, :update, :destroy, :request_access,
                                  :approve_access_request, :leave, :resend_invite,
                                  :override

  feature_category :authentication_and_authorization

  helper_method :can_manage_members?

  def index
    preload_max_access
    @sort = params[:sort].presence || sort_value_name

    @members = GroupMembersFinder
      .new(@group, current_user, params: filter_params)
      .execute(include_relations: requested_relations)

    if can_manage_members?
      @skip_groups = @group.related_group_ids

      @invited_members = @members.invite
      @invited_members = @invited_members.search_invite_email(params[:search_invited]) if params[:search_invited].present?
      @invited_members = present_invited_members(@invited_members)
    end

    @members = present_group_members(@members.non_invite)

    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user)
    )

    @group_member = @group.group_members.new
  end

  # MembershipActions concern
  alias_method :membershipable, :group

  private

  def preload_max_access
    return unless current_user

    # this allows the can? against admin type queries in this action to
    # only perform the query once, even if it is cached
    current_user.max_access_for_group[@group.id] = @group.max_member_access(current_user)
  end

  def can_manage_members?
    strong_memoize(:can_manage_members) do
      can?(current_user, :admin_group_member, @group)
    end
  end

  def present_invited_members(invited_members)
    present_members(invited_members
      .page(params[:invited_members_page])
      .per(MEMBER_PER_PAGE_LIMIT))
  end

  def present_group_members(members)
    present_members(members
      .page(params[:page])
      .per(MEMBER_PER_PAGE_LIMIT))
  end

  def filter_params
    params.permit(:two_factor, :search).merge(sort: @sort)
  end

  def membershipable_members
    group.members
  end
end

Groups::GroupMembersController.prepend_mod_with('Groups::GroupMembersController')
