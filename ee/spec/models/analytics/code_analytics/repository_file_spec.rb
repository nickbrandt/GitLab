# frozen_string_literal: true

require 'spec_helper'

describe Analytics::CodeAnalytics::RepositoryFile do
  it { is_expected.to belong_to(:project) }
end
