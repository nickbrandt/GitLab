# frozen_string_literal: true

require 'spec_helper'

describe ::TodosHelper do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:issue) { create(:issue) }
  let_it_be(:design) { create(:design, issue: issue) }
  let_it_be(:note) do
    create(:note,
           project: issue.project,
           note: "I am note, hear me roar")
  end
  let_it_be(:design_todo) do
    create(:todo, :mentioned,
           user: user,
           project: issue.project,
           target: design,
           author: author,
           note: note)
  end
  let(:project) { issue.project }

  describe '#todo_target_link' do
    context 'when given a design' do
      let(:todo) { design_todo }

      it 'produces a good link' do
        path = helper.todo_target_path(todo)
        link = helper.todo_target_link(todo)
        expected = "<a href=\"#{path}\">design #{design.to_reference}</a>"

        expect(link).to eq(expected)
      end
    end
  end

  describe '#todo_target_path' do
    context 'when given a design' do
      let(:todo) { design_todo }

      it 'responds with an appropriate path' do
        path = helper.todo_target_path(todo)
        issue_path = Gitlab::Routing.url_helpers
          .project_issue_path(project, issue)

        expect(path).to eq("#{issue_path}/designs/#{design.filename}##{dom_id(design_todo.note)}")
      end
    end
  end

  describe '#todo_types_options' do
    it 'includes a match for a design todo' do
      options = helper.todo_types_options
      design_option = options.find { |o| o[:id] == design_todo.target_type }

      expect(design_option).to include(text: 'Design')
    end
  end
end
