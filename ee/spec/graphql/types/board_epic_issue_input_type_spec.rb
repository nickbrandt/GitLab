# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['BoardEpicIssueInput'] do
  it { expect(described_class.graphql_name).to eq('BoardEpicIssueInput') }

  it 'exposes negated issue arguments' do
    allowed_args = %w(labelName milestoneTitle assigneeUsername authorUsername
                      releaseTag epicId myReactionEmoji weight not)

    expect(described_class.arguments.keys).to match_array(allowed_args)
    expect(described_class.arguments['not'].type).to eq(Types::NegatedBoardEpicIssueInputType)
  end
end
