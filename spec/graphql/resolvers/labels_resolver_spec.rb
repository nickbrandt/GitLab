# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::LabelsResolver do
  include GraphqlHelpers

  let(:current_user) { create(:user) }

  context "with a project" do
    context "with an issue" do
      set(:project) { create(:project) }
      set(:issue) { create(:issue, project: project, state: :opened) }
      set(:label1) { create(:label, project: project, title: 'test-label') }
      set(:label2) { create(:label, project: project) }
      set(:label3) { create(:label, project: project) }

      before do
        project.add_developer(current_user)
        create(:label_link, label: label1, target: issue)
        create(:label_link, label: label2, target: issue)
        create(:label_link, label: label3, target: issue)
        label1.subscribe(current_user)
      end

      describe '#resolve' do
        it 'finds all issues' do
          expect(resolve_labels).to contain_exactly(label1, label2, label3)
        end

        it 'filters by title' do
          expect(resolve_labels(title: 'test-label')).to contain_exactly(label1)
        end

        it 'searches labels' do
          expect(resolve_labels(search: 'test-label')).to contain_exactly(label1)
        end

        it 'sort labels' do
          expect(resolve_labels(sort: 'created_desc')).to eq [label3, label2, label1]
        end

        it 'returns labels user is subscribed to' do
          expect(resolve_labels(subscribed: 'true')).to contain_exactly(label1)
        end
      end
    end
  end

  def resolve_labels(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: issue, args: args, ctx: context)
  end
end
