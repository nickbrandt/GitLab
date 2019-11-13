# frozen_string_literal: true

require 'spec_helper'

describe SourcegraphGon do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  controller(Projects::ApplicationController) do
    include SourcegraphGon # rubocop:disable RSpec/DescribedClass

    def index; end
  end

  describe '#push_sourcegraph_gon' do
    let(:application_setting_sourcegraph_url) { 'http://gitlab.com' }
    let(:sourcegraph_access) { true }

    subject { get(:index, params: { namespace_id: project.namespace, project_id: project })}

    before do
      stub_application_setting(sourcegraph_url: application_setting_sourcegraph_url)

      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:can?).and_return(true)
      allow(controller).to receive(:can?).with(user, :access_sourcegraph, project).and_return(sourcegraph_access)

      subject
    end

    context 'with access to use sourcegraph' do
      it 'enables sourcegraph' do
        expect(Gon.sourcegraph_enabled).to be_truthy
        expect(Gon.sourcegraph_url).to eq application_setting_sourcegraph_url
      end
    end

    context 'with no access to use sourcegraph' do
      let(:sourcegraph_access) { false }

      it 'does not enable sourcegraph' do
        expect(Gon.sourcegraph_enabled).to be_nil
        expect(Gon.sourcegraph_url).to be_nil
      end
    end
  end
end
