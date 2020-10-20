# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Explore routing' do
  describe 'root path' do
    include RSpec::Rails::RequestExampleGroup

    subject { get('/explore') }

    it { is_expected.to redirect_to('/explore/projects') }
  end

  describe Explore::ProjectsController, 'routing' do
    it 'to #index' do
      expect(get('/explore/projects')).to route_to('explore/projects#index')
    end

    it 'to #trending' do
      expect(get('/explore/projects/trending')).to route_to('explore/projects#trending')
    end

    it 'to #starred' do
      expect(get('/explore/projects/starred')).to route_to('explore/projects#starred')
    end
  end

  describe Explore::SnippetsController, 'routing' do
    it 'to #index' do
      expect(get('/explore/snippets')).to route_to('explore/snippets#index')
    end
  end

  describe Explore::GroupsController, 'routing' do
    it 'to #index' do
      expect(get('/explore/groups')).to route_to('explore/groups#index')
    end
  end
end
