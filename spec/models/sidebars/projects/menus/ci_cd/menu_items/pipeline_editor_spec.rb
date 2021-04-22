# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::CiCd::MenuItems::PipelineEditor do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project, can_view_pipeline_editor: pipeline_editor_status) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when user can view pipeline editor' do
      let(:pipeline_editor_status) { true }

      it 'returns true' do
        expect(subject.render?).to eq true
      end
    end

    context 'when user cannot read builds' do
      let(:pipeline_editor_status) { false }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end
end
