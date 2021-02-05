# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::ProjectIntegrationActivityCounter do
  it_behaves_like 'a redis usage counter', 'Chat Notification', :slack

  it_behaves_like 'a redis usage counter with totals', :project_integration_activity, slack: 8
end
