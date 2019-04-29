# frozen_string_literal: true

require 'spec_helper'

describe SystemHooksService do
  let(:group_member)   { create(:group_member) }

  context 'event data' do
    it { expect(event_data(group_member, :create)).to include(:event_name, :created_at, :updated_at, :group_name, :group_path, :group_plan, :group_id, :user_name, :user_username, :user_email, :user_id, :group_access) }
    it { expect(event_data(group_member, :destroy)).to include(:event_name, :created_at, :updated_at, :group_name, :group_path, :group_plan, :group_id, :user_name, :user_username, :user_email, :user_id, :group_access) }
  end

  def event_data(*args)
    SystemHooksService.new.send :build_event_data, *args
  end
end
