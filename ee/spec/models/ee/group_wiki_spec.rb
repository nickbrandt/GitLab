# frozen_string_literal: true

require 'spec_helper'

describe GroupWiki do
  it_behaves_like 'EE wiki model' do
    let(:wiki_container) { create(:group, :wiki_repo) }

    before do
      wiki_container.add_owner(user)
    end

    it 'does not use Elasticsearch' do
      expect(subject).not_to be_a(Elastic::WikiRepositoriesSearch)
    end
  end
end
