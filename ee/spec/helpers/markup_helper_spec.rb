# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MarkupHelper do
  let_it_be(:project) { create(:project, :public) }

  describe '#first_line_in_markdown' do
    context 'with scoped label references' do
      let(:label) { create(:label, title: 'key::some name', project: project) }

      before do
        stub_licensed_features(scoped_labels: true)
      end

      it 'shows proper tooltip' do
        note = build(:note, note: label.to_reference, project: project)

        result = first_line_in_markdown(note, :note, nil, project: project)
        doc = Nokogiri::HTML.parse(result)

        expect(doc.css('.gl-label-link')[0].attr('data-html')).to eq('true')
      end
    end
  end

  describe '#render_wiki_content' do
    subject { helper.render_wiki_content(wiki_page) }

    context 'when file is Markdown' do
      context 'when content has labels' do
        let(:wiki_page) { create(:wiki_page, format: :markdown, wiki: wiki, title: 'merge', content: '~Bug') }

        before do
          allow(helper).to receive(:current_user).and_return(nil)

          helper.instance_variable_set(:@wiki, wiki_page.wiki)
        end

        shared_examples 'renders label' do
          specify do
            result = subject
            doc = Nokogiri::HTML.parse(result)

            expect(doc.css('.gl-label-link')).not_to be_empty
          end
        end

        context 'when wiki is a group wiki' do
          let_it_be(:user) { create(:user) }
          let_it_be(:group) { create(:group) }
          let_it_be(:label) { create(:group_label, group: group, title: 'Bug') }

          let(:wiki) { create(:group_wiki, group: group, user: user) }

          it_behaves_like 'renders label'
        end

        context 'when wiki is a project wiki' do
          let_it_be(:label) { create(:label, title: 'Bug', project: project) }

          let(:wiki) { create(:project_wiki, project: project) }

          it_behaves_like 'renders label'
        end
      end
    end
  end
end
