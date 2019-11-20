# frozen_string_literal: true

require "spec_helper"

describe IssuesHelper do
  let(:project) { create(:project) }
  let(:issue) { create :issue, project: project }

  describe '#issue_closed_link' do
    let(:new_epic) { create(:epic) }
    let(:user)     { create(:user) }

    context 'with linked issue' do
      context 'with promoted issue' do
        before do
          issue.update(promoted_to_epic: new_epic)
        end

        context 'when user has permission to see new epic' do
          before do
            expect(helper).to receive(:can?).with(user, :read_epic, new_epic) { true }
          end

          let(:css_class) { 'text-white text-underline' }

          it 'returns link' do
            link = "<a class=\"#{css_class}\" href=\"/groups/#{new_epic.group.full_path}/-/epics/#{new_epic.iid}\">(promoted)</a>"

            expect(helper.issue_closed_link(issue, user, css_class: css_class)).to match(link)
          end
        end

        context 'when user has no permission to see new epic' do
          before do
            expect(helper).to receive(:can?).with(user, :read_epic, new_epic) { false }
          end

          it 'returns nil' do
            expect(helper.issue_closed_link(issue, user)).to be_nil
          end
        end
      end
    end
  end
end
