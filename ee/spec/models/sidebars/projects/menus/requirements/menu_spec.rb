# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::Requirements::Menu do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    before do
      stub_licensed_features(requirements: true)
    end

    context 'when user can read requirements' do
      it 'returns true' do
        expect(subject.render?).to be true
      end
    end

    context 'when user can not read requirements' do
      let(:user) { nil }

      it 'returns false' do
        expect(subject.render?).to be false
      end
    end
  end

  context 'when feature flag :project_sidebar_refactor is enabled' do
    it 'menu item List is not added to the menu' do
      stub_feature_flags(project_sidebar_refactor: true)

      expect(subject.instance_variable_get(:@items)).to be_empty
    end
  end

  context 'when feature flag :project_sidebar_refactor is disabled' do
    it 'menu item List is added to the menu' do
      stub_feature_flags(project_sidebar_refactor: false)

      items = subject.instance_variable_get(:@items)

      expect(items[0]).to be_a(Sidebars::Projects::Menus::Requirements::MenuItems::List)
    end
  end
end
