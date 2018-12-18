# frozen_string_literal: true

require 'spec_helper'

describe Constraints::JiraEncodedUrlConstrainer do
  describe '#matches?' do
    using RSpec::Parameterized::TableSyntax

    where(:path, :match_result) do
      "/-/jira/group/project"                                                  | true
      "/-/jira/group/sub_group#{Gitlab::Jira::Dvcs::ENCODED_SLASH}sub_project" | true
      "/group/sub_group#{Gitlab::Jira::Dvcs::ENCODED_SLASH}sub_project"        | true
      "/group/project"                                                         | false
    end

    with_them do
      it 'matches path with /-/jira prefix or encoded slash' do
        request = build_request(path)

        expect(subject.matches?(request)).to eq(match_result)
      end
    end
  end

  def build_request(path)
    double(:request, path: path)
  end
end
