# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::GroupTreeSaver do
  describe 'saves the group tree into a json object' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:epic) { create(:epic, group: group) }
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:export_path) { "#{Dir.tmpdir}/group_tree_saver_spec_ee" }
    let(:group_tree_saver) { described_class.new(group: group, current_user: user, shared: shared) }
    let(:saved_group_json) do
      group_tree_saver.save
      group_json(group_tree_saver.full_path)
    end

    before do
      group.add_maintainer(user)
    end

    after do
      FileUtils.rm_rf(export_path)
    end

    it 'saves successfully' do
      expect(group_tree_saver.save).to be true
    end

    it 'saves epics' do
      expect(saved_group_json['epics'].size).to eq(1)
    end
  end

  def group_json(filename)
    JSON.parse(IO.read(filename))
  end
end
