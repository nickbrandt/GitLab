require 'spec_helper'

describe Issue do
  using RSpec::Parameterized::TableSyntax
  include ExternalAuthorizationServiceHelpers

  describe 'validations' do
    subject { build(:issue) }

    describe 'weight' do
      it 'is not valid when negative number' do
        subject.weight = -1

        expect(subject).not_to be_valid
        expect(subject.errors[:weight]).not_to be_empty
      end

      it 'is valid when non-negative' do
        subject.weight = 0

        expect(subject).to be_valid

        subject.weight = 1

        expect(subject).to be_valid
      end
    end
  end

  describe '#related_issues' do
    let(:user) { create(:user) }
    let(:authorized_project) { create(:project) }
    let(:authorized_project2) { create(:project) }
    let(:unauthorized_project) { create(:project) }

    let(:authorized_issue_a) { create(:issue, project: authorized_project) }
    let(:authorized_issue_b) { create(:issue, project: authorized_project) }
    let(:authorized_issue_c) { create(:issue, project: authorized_project2) }

    let(:unauthorized_issue) { create(:issue, project: unauthorized_project) }

    let!(:issue_link_a) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_b) }
    let!(:issue_link_b) { create(:issue_link, source: authorized_issue_a, target: unauthorized_issue) }
    let!(:issue_link_c) { create(:issue_link, source: authorized_issue_a, target: authorized_issue_c) }

    before do
      authorized_project.add_developer(user)
      authorized_project2.add_developer(user)
    end

    it 'returns only authorized related issues for given user' do
      expect(authorized_issue_a.related_issues(user))
          .to contain_exactly(authorized_issue_b, authorized_issue_c)
    end

    describe 'when a user cannot read cross project' do
      it 'only returns issues within the same project' do
        expect(Ability).to receive(:allowed?).with(user, :read_cross_project)
                               .and_return(false)

        expect(authorized_issue_a.related_issues(user))
            .to contain_exactly(authorized_issue_b)
      end
    end
  end

  describe '#allows_multiple_assignees?' do
    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: false)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_falsey
    end

    it 'does not allow multiple assignees without license' do
      stub_licensed_features(multiple_issue_assignees: true)

      issue = build(:issue)

      expect(issue.allows_multiple_assignees?).to be_truthy
    end
  end

  describe '#sort' do
    let(:project) { create(:project) }

    context "by weight" do
      let!(:issue)  { create(:issue, project: project) }
      let!(:issue2) { create(:issue, weight: 1, project: project) }
      let!(:issue3) { create(:issue, weight: 2, project: project) }
      let!(:issue4) { create(:issue, weight: 3, project: project) }

      it "sorts desc" do
        issues = project.issues.sort_by_attribute('weight_desc')
        expect(issues).to eq([issue4, issue3, issue2, issue])
      end

      it "sorts asc" do
        issues = project.issues.sort_by_attribute('weight_asc')
        expect(issues).to eq([issue2, issue3, issue4, issue])
      end
    end
  end

  describe '#weight' do
    where(:license_value, :database_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:issue) { build(:issue, weight: database_value) }

      subject { issue.weight }

      before do
        stub_licensed_features(issue_weights: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  context 'when an external authentication service' do
    before do
      enable_external_authorization_service_check
    end

    describe '#publicly_visible?' do
      it 'is `false` when an external authorization service is enabled' do
        issue = build(:issue, project: build(:project, :public))

        expect(issue).not_to be_publicly_visible
      end
    end

    describe '#readable_by?' do
      it 'checks the external service to determine if an issue is readable by a user' do
        project = build(:project, :public,
                        external_authorization_classification_label: 'a-label')
        issue = build(:issue, project: project)
        user = build(:user)

        expect(EE::Gitlab::ExternalAuthorization).to receive(:access_allowed?).with(user, 'a-label') { false }
        expect(issue.readable_by?(user)).to be_falsy
      end

      it 'does not check the external webservice for admins' do
        issue = build(:issue)
        user = build(:admin)

        expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        issue.readable_by?(user)
      end

      it 'does not check the external webservice for auditors' do
        issue = build(:issue)
        user = build(:auditor)

        expect(EE::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        issue.readable_by?(user)
      end
    end
  end

  describe 'relative positioning with group boards' do
    let(:group) { create(:group) }
    let!(:board) { create(:board, group: group) }
    let(:project) { create(:project, namespace: group) }
    let(:project1) { create(:project, namespace: group) }
    let(:issue) { create(:issue, project: project) }
    let(:issue1) { create(:issue, project: project1) }
    let(:new_issue) { create(:issue, project: project1) }

    before do
      [issue, issue1].each do |issue|
        issue.move_to_end && issue.save
      end
    end

    describe '#max_relative_position' do
      it 'returns maximum position' do
        expect(issue.max_relative_position).to eq issue1.relative_position
      end
    end

    describe '#prev_relative_position' do
      it 'returns previous position if there is an issue above' do
        expect(issue1.prev_relative_position).to eq issue.relative_position
      end

      it 'returns nil if there is no issue above' do
        expect(issue.prev_relative_position).to eq nil
      end
    end

    describe '#next_relative_position' do
      it 'returns next position if there is an issue below' do
        expect(issue.next_relative_position).to eq issue1.relative_position
      end

      it 'returns nil if there is no issue below' do
        expect(issue1.next_relative_position).to eq nil
      end
    end

    describe '#move_before' do
      it 'moves issue before' do
        [issue1, issue].each(&:move_to_end)

        issue.move_before(issue1)

        expect(issue.relative_position).to be < issue1.relative_position
      end
    end

    describe '#move_after' do
      it 'moves issue after' do
        [issue, issue1].each(&:move_to_end)

        issue.move_after(issue1)

        expect(issue.relative_position).to be > issue1.relative_position
      end
    end

    describe '#move_to_end' do
      it 'moves issue to the end' do
        new_issue.move_to_end

        expect(new_issue.relative_position).to be > issue1.relative_position
      end
    end

    describe '#shift_after?' do
      it 'returns true' do
        issue.update(relative_position: issue1.relative_position - 1)

        expect(issue.shift_after?).to be_truthy
      end

      it 'returns false' do
        issue.update(relative_position: issue1.relative_position - 2)

        expect(issue.shift_after?).to be_falsey
      end
    end

    describe '#shift_before?' do
      it 'returns true' do
        issue.update(relative_position: issue1.relative_position + 1)

        expect(issue.shift_before?).to be_truthy
      end

      it 'returns false' do
        issue.update(relative_position: issue1.relative_position + 2)

        expect(issue.shift_before?).to be_falsey
      end
    end

    describe '#move_between' do
      it 'positions issue between two other' do
        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to be > issue.relative_position
        expect(new_issue.relative_position).to be < issue1.relative_position
      end

      it 'positions issue between on top' do
        new_issue.move_between(nil, issue)

        expect(new_issue.relative_position).to be < issue.relative_position
      end

      it 'positions issue between to end' do
        new_issue.move_between(issue1, nil)

        expect(new_issue.relative_position).to be > issue1.relative_position
      end

      it 'positions issues even when after and before positions are the same' do
        issue1.update relative_position: issue.relative_position

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to be > issue.relative_position
        expect(issue.relative_position).to be < issue1.relative_position
      end

      it 'positions issues between other two if distance is 1' do
        issue1.update relative_position: issue.relative_position + 1

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to be > issue.relative_position
        expect(issue.relative_position).to be < issue1.relative_position
      end

      it 'positions issue in the middle of other two if distance is big enough' do
        issue.update relative_position: 6000
        issue1.update relative_position: 10000

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to eq(8000)
      end

      it 'positions issue closer to the middle if we are at the very top' do
        issue1.update relative_position: 6000

        new_issue.move_between(nil, issue1)

        expect(new_issue.relative_position).to eq(6000 - RelativePositioning::IDEAL_DISTANCE)
      end

      it 'positions issue closer to the middle if we are at the very bottom' do
        issue.update relative_position: 6000
        issue1.update relative_position: nil

        new_issue.move_between(issue, nil)

        expect(new_issue.relative_position).to eq(6000 + RelativePositioning::IDEAL_DISTANCE)
      end

      it 'positions issue in the middle of other two if distance is not big enough' do
        issue.update relative_position: 100
        issue1.update relative_position: 400

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to eq(250)
      end

      it 'positions issue in the middle of other two is there is no place' do
        issue.update relative_position: 100
        issue1.update relative_position: 101

        new_issue.move_between(issue, issue1)

        expect(new_issue.relative_position).to be_between(issue.relative_position, issue1.relative_position)
      end

      it 'uses rebalancing if there is no place' do
        issue.update relative_position: 100
        issue1.update relative_position: 101
        issue2 = create(:issue, relative_position: 102, project: project)
        new_issue.update relative_position: 103

        new_issue.move_between(issue1, issue2)
        new_issue.save!

        expect(new_issue.relative_position).to be_between(issue1.relative_position, issue2.relative_position)
        expect(issue.reload.relative_position).not_to eq(100)
      end

      it 'positions issue right if we pass none-sequential parameters' do
        issue.update relative_position: 99
        issue1.update relative_position: 101
        issue2 = create(:issue, relative_position: 102, project: project)
        new_issue.update relative_position: 103

        new_issue.move_between(issue, issue2)
        new_issue.save!

        expect(new_issue.relative_position).to be(100)
      end
    end
  end
end
