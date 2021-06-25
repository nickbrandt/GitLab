# frozen_string_literal: true

require "spec_helper"

RSpec.describe 'Project wikis' do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :wiki_repo, namespace: user.namespace, creator: user) }
  let(:wiki) { project.wiki }

  it_behaves_like 'User creates wiki page'
  it_behaves_like 'User deletes wiki page'
  it_behaves_like 'User previews wiki changes'
  it_behaves_like 'User updates wiki page'
  it_behaves_like 'User uses wiki shortcuts'
  it_behaves_like 'User views AsciiDoc page with includes'
  it_behaves_like 'User views a wiki page'
  it_behaves_like 'User views wiki pages'
  it_behaves_like 'User views wiki sidebar'
  it_behaves_like 'User views Git access wiki page'
end
