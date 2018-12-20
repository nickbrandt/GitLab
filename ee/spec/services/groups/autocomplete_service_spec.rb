require 'spec_helper'

describe Groups::AutocompleteService do
  let!(:group) { create(:group, :nested, :private, avatar: fixture_file_upload('spec/fixtures/dk.png')) }
  let!(:sub_group) { create(:group, :private, parent: group) }
  let(:user) { create(:user) }
  let!(:epic) { create(:epic, group: group, author: user) }

  subject { described_class.new(group, user) }

  before do
    group.add_developer(user)
  end

  def expect_labels_to_equal(labels, expected_labels)
    extract_title = lambda { |label| label['title'] }
    expect(labels.map(&extract_title)).to eq(expected_labels.map(&extract_title))
  end

  describe '#labels_as_hash' do
    let!(:label1) { create(:group_label, group: group) }
    let!(:label2) { create(:group_label, group: group) }
    let!(:sub_group_label) { create(:group_label, group: sub_group) }
    let!(:parent_group_label) { create(:group_label, group: group.parent, group_id: group.id) }

    it 'returns labels from own group and ancestor groups' do
      results = subject.labels_as_hash(nil)

      expected_labels = [label1, label2, parent_group_label]

      expect_labels_to_equal(results, expected_labels)
    end

    context 'some labels are already assigned' do
      before do
        epic.labels << label1
      end

      it 'marks already assigned as set' do
        results = subject.labels_as_hash(epic)
        expected_labels = [label1, label2, parent_group_label]

        expect_labels_to_equal(results, expected_labels)

        assigned_label_titles = epic.labels.map(&:title)
        results.each do |hash|
          if assigned_label_titles.include?(hash['title'])
            expect(hash[:set]).to eq(true)
          else
            expect(hash.key?(:set)).to eq(false)
          end
        end
      end
    end
  end

  describe '#issues', :nested_groups do
    let(:project) { create(:project, group: group) }
    let(:sub_group_project) { create(:project, group: sub_group) }

    let!(:project_issue) { create(:issue, project: project) }
    let!(:sub_group_project_issue) { create(:issue, project: sub_group_project) }

    it 'returns issues in group and subgroups' do
      expect(subject.issues.map(&:iid)).to contain_exactly(project_issue.iid, sub_group_project_issue.iid)
      expect(subject.issues.map(&:title)).to contain_exactly(project_issue.title, sub_group_project_issue.title)
    end
  end

  describe '#merge_requests', :nested_groups do
    let(:project) { create(:project, :repository, group: group) }
    let(:sub_group_project) { create(:project, :repository, group: sub_group) }

    let!(:project_mr) { create(:merge_request, source_project: project) }
    let!(:sub_group_project_mr) { create(:merge_request, source_project: sub_group_project) }

    it 'returns merge requests in group and subgroups' do
      expect(subject.merge_requests.map(&:iid)).to contain_exactly(project_mr.iid, sub_group_project_mr.iid)
      expect(subject.merge_requests.map(&:title)).to contain_exactly(project_mr.title, sub_group_project_mr.title)
    end
  end

  describe '#epics' do
    it 'returns nothing if not allowed' do
      allow(Ability).to receive(:allowed?).with(user, :read_epic, group).and_return(false)

      expect(subject.epics).to eq([])
    end

    it 'returns epics from group' do
      allow(Ability).to receive(:allowed?).with(user, :read_epic, group).and_return(true)

      expect(subject.epics.map(&:iid)).to contain_exactly(epic.iid)
    end
  end

  describe '#commands' do
    context 'when target is an epic' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'returns available commands' do
        expect(subject.commands(epic).map { |c| c[:name] })
          .to match_array(
            [:todo, :unsubscribe, :award, :shrug, :tableflip, :cc, :title, :close]
          )
      end
    end
  end

  describe '#milestones' do
    let!(:group_milestone) { create(:milestone, group: group) }
    let!(:subgroup_milestone) { create(:milestone, group: sub_group) }

    before do
      sub_group.add_master(user)
    end

    context 'when group is public' do
      let(:public_group) { create(:group, :public) }
      let(:public_subgroup) { create(:group, :public, parent: public_group) }

      before do
        public_subgroup.add_guest(user)
        public_group.add_guest(user)

        group_milestone.update(group: public_group)
        subgroup_milestone.update(group: public_subgroup)
      end

      it 'returns milestones from groups and subgroups', :nested_groups do
        subject = described_class.new(public_subgroup, user)

        expect(subject.milestones.map(&:iid)).to contain_exactly(group_milestone.iid, subgroup_milestone.iid)
        expect(subject.milestones.map(&:title)).to contain_exactly(group_milestone.title, subgroup_milestone.title)
      end
    end

    it 'returns milestones from group' do
      expect(subject.milestones.map(&:iid)).to contain_exactly(group_milestone.iid)
      expect(subject.milestones.map(&:title)).to contain_exactly(group_milestone.title)
    end

    it 'returns milestones from groups and subgroups', :nested_groups do
      milestones = described_class.new(sub_group, user).milestones

      expect(milestones.map(&:iid)).to contain_exactly(group_milestone.iid, subgroup_milestone.iid)
      expect(milestones.map(&:title)).to contain_exactly(group_milestone.title, subgroup_milestone.title)
    end

    it 'returns only milestones that user can read', :nested_groups do
      user = create(:user)
      sub_group.add_guest(user)

      milestones = described_class.new(sub_group, user).milestones

      expect(milestones.map(&:iid)).to contain_exactly(subgroup_milestone.iid)
      expect(milestones.map(&:title)).to contain_exactly(subgroup_milestone.title)
    end
  end
end
