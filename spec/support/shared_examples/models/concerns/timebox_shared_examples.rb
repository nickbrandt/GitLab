# frozen_string_literal: true

RSpec.shared_examples 'a timebox' do |timebox_type|
  let(:project) { create(:project, :public) }
  let(:timebox) { create(timebox_type.to_sym, project: project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe 'modules' do
    context 'with a project' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(timebox_type.to_sym, project: build(:project), group: nil) }
        let(:scope) { :project }
        let(:scope_attrs) { { project: instance.project } }
        let(:usage) {timebox_type.pluralize.to_sym }
      end
    end

    context 'with a group' do
      it_behaves_like 'AtomicInternalId' do
        let(:internal_id_attribute) { :iid }
        let(:instance) { build(timebox_type.to_sym, project: nil, group: build(:group)) }
        let(:scope) { :group }
        let(:scope_attrs) { { namespace: instance.group } }
        let(:usage) {timebox_type.pluralize.to_sym }
      end
    end
  end

  describe "Validation" do
    before do
      allow(subject).to receive(:set_iid).and_return(false)
    end

    describe 'start_date' do
      it 'adds an error when start_date is greater then due_date' do
        timebox = build(timebox_type.to_sym, start_date: Date.tomorrow, due_date: Date.yesterday)

        expect(timebox).not_to be_valid
        expect(timebox.errors[:due_date]).to include("must be greater than start date")
      end

      it 'adds an error when start_date is greater than 9999-12-31' do
        timebox = build(timebox_type.to_sym, start_date: Date.new(10000, 1, 1))

        expect(timebox).not_to be_valid
        expect(timebox.errors[:start_date]).to include("date must not be after 9999-12-31")
      end
    end

    describe 'due_date' do
      it 'adds an error when due_date is greater than 9999-12-31' do
        timebox = build(timebox_type.to_sym, due_date: Date.new(10000, 1, 1))

        expect(timebox).not_to be_valid
        expect(timebox.errors[:due_date]).to include("date must not be after 9999-12-31")
      end
    end

    describe 'title' do
      it { is_expected.to validate_presence_of(:title) }

      it 'is invalid if title would be empty after sanitation' do
        timebox = build(timebox_type.to_sym, project: project, title: '<img src=x onerror=prompt(1)>')

        expect(timebox).not_to be_valid
        expect(timebox.errors[:title]).to include("can't be blank")
      end
    end
  end

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:issues) }
    it { is_expected.to have_many(:merge_requests) }
  end

  describe "#title" do
    let(:timebox) { create(timebox_type.to_sym, title: "<b>foo & bar -> 2.2</b>") }

    it "sanitizes title" do
      expect(timebox.title).to eq("foo & bar -> 2.2")
    end
  end

  describe '#merge_requests_enabled?' do
    context "per project" do
      it "is true for projects with MRs enabled" do
        project = create(:project, :merge_requests_enabled)
        timebox = create(timebox_type.to_sym, project: project)

        expect(timebox.merge_requests_enabled?).to be(true)
      end

      it "is false for projects with MRs disabled" do
        project = create(:project, :repository_enabled, :merge_requests_disabled)
        timebox = create(timebox_type.to_sym, project: project)

        expect(timebox.merge_requests_enabled?).to be(false)
      end

      it "is false for projects with repository disabled" do
        project = create(:project, :repository_disabled)
        timebox = create(timebox_type.to_sym, project: project)

        expect(timebox.merge_requests_enabled?).to be(false)
      end
    end

    context "per group" do
      let(:group) { create(:group) }
      let(:timebox) { create(timebox_type.to_sym, group: group) }

      it "is always true for groups, for performance reasons" do
        expect(timebox.merge_requests_enabled?).to be(true)
      end
    end
  end

  describe "unique timebox title" do
    context "per project" do
      it "does not accept the same title in a project twice" do
        new_timebox = described_class.new(project: timebox.project, title: timebox.title)
        expect(new_timebox).not_to be_valid
      end

      it "accepts the same title in another project" do
        project = create(:project)
        new_timebox = described_class.new(project: project, title: timebox.title)

        expect(new_timebox).to be_valid
      end
    end

    context "per group" do
      let(:group) { create(:group) }
      let(:timebox) { create(timebox_type.to_sym, group: group) }

      before do
        project.update(group: group)
      end

      it "does not accept the same title in a group twice" do
        new_timebox = described_class.new(group: group, title: timebox.title)

        expect(new_timebox).not_to be_valid
      end

      it "does not accept the same title of a child project timebox" do
        create(timebox_type.to_sym, project: group.projects.first)

        new_timebox = described_class.new(group: group, title: timebox.title)

        expect(new_timebox).not_to be_valid
      end
    end
  end

  it_behaves_like 'within_timeframe scope' do
    let_it_be(:now) { Time.now }
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:resource_1) { create(timebox_type.to_sym, project: project, start_date: now - 1.day, due_date: now + 1.day) }
    let_it_be(:resource_2) { create(timebox_type.to_sym, project: project, start_date: now + 2.days, due_date: now + 3.days) }
    let_it_be(:resource_3) { create(timebox_type.to_sym, project: project, due_date: now) }
    let_it_be(:resource_4) { create(timebox_type.to_sym, project: project, start_date: now) }
  end

  describe "#percent_complete" do
    it "does not count open issues" do
      timebox.issues << issue
      expect(timebox.percent_complete).to eq(0)
    end

    it "counts closed issues" do
      issue.close
      timebox.issues << issue
      expect(timebox.percent_complete).to eq(100)
    end

    it "recovers from dividing by zero" do
      expect(timebox.percent_complete).to eq(0)
    end
  end

  describe '#expired?' do
    context "expired" do
      before do
        allow(timebox).to receive(:due_date).and_return(Date.today.prev_year)
      end

      it 'returns true when due_date is in the past' do
        expect(timebox.expired?).to be_truthy
      end
    end

    context "not expired" do
      before do
        allow(timebox).to receive(:due_date).and_return(Date.today.next_year)
      end

      it 'returns false when due_date is in the future' do
        expect(timebox.expired?).to be_falsey
      end
    end
  end

  describe '#upcoming?' do
    it 'returns true when start_date is in the future' do
      timebox = build(timebox_type.to_sym, start_date: Time.now + 1.month)
      expect(timebox.upcoming?).to be_truthy
    end

    it 'returns false when start_date is in the past' do
      timebox = build(timebox_type.to_sym, start_date: Date.today.prev_year)
      expect(timebox.upcoming?).to be_falsey
    end
  end

  describe '#can_be_closed?' do
    let(:timebox) { create(timebox_type.to_sym, project: project) }

    before do
      create :closed_issue, timebox_type => timebox, project: project

      create :issue, project: project
    end

    it 'returns true if timebox active and all nested issues closed' do
      expect(timebox.can_be_closed?).to be_truthy
    end

    it 'returns false if timebox active and not all nested issues closed' do
      issue.send(:"#{timebox_type}=", timebox)
      issue.save

      expect(timebox.can_be_closed?).to be_falsey
    end
  end

  describe '#to_ability_name' do
    it 'returns timebox' do
      timebox = build(timebox_type.to_sym)

      expect(timebox.to_ability_name).to eq(timebox_type)
    end
  end

  describe '#to_reference' do
    let(:group) { build_stubbed(:group) }
    let(:project) { build_stubbed(:project, name: 'sample-project') }
    let(:another_project) { build_stubbed(:project, name: 'another-project', namespace: project.namespace) }

    context 'for a project timebox' do
      let(:timebox) { build_stubbed(timebox_type.to_sym, iid: 1, project: project, name: 'timebox') }

      it 'returns a String reference to the object' do
        expect(timebox.to_reference).to eq '%"timebox"'
      end

      it 'returns a reference by name when the format is set to :name' do
        expect(timebox.to_reference(format: :name)).to eq '%"timebox"'
      end

      it 'returns a reference by id even if format is set to :name if the name includes a quote' do
        timebox = build_stubbed(timebox_type.to_sym, iid: 1, project: project, name: 'timebox "a"')

        expect(timebox.to_reference(format: :name)).to eq '%1'
      end

      it 'supports a cross-project reference' do
        expect(timebox.to_reference(another_project)).to eq 'sample-project%"timebox"'
      end
    end

    context 'for a group timebox' do
      let(:timebox) { build_stubbed(timebox_type.to_sym, iid: 1, group: group, name: 'timebox') }

      it 'returns a group timebox reference with a default format' do
        expect(timebox.to_reference).to eq '%"timebox"'
      end

      it 'returns a reference by name when the format is set to :name' do
        expect(timebox.to_reference(format: :name)).to eq '%"timebox"'
      end

      it 'does supports cross-project references within a group' do
        expect(timebox.to_reference(another_project, format: :name)).to eq '%"timebox"'
      end

      it 'returns a reference by id even if format is set to :name if the name includes a quote' do
        timebox = build_stubbed(timebox_type.to_sym, iid: 1, project: project, name: 'timebox "a"')

        expect(timebox.to_reference(format: :name)).to eq '%1'
      end

      it 'raises an error when using iid format' do
        expect { timebox.to_reference(format: :iid) }
            .to raise_error(ArgumentError, "Cannot refer to a group #{timebox_type} by an internal id!")
      end
    end
  end
end
