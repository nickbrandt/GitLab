# frozen_string_literal: true

require 'spec_helper'

describe Sprint do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }

  it_behaves_like 'a timebox', :sprint

  describe "#iid" do
    it "is properly scoped on project and group" do
      sprint1 = create(:sprint, project: project)
      sprint2 = create(:sprint, project: project)
      sprint3 = create(:sprint, group: group)
      sprint4 = create(:sprint, group: group)
      sprint5 = create(:sprint, project: project)

      want = {
          sprint1: 1,
          sprint2: 2,
          sprint3: 1,
          sprint4: 2,
          sprint5: 3
      }
      got = {
          sprint1: sprint1.iid,
          sprint2: sprint2.iid,
          sprint3: sprint3.iid,
          sprint4: sprint4.iid,
          sprint5: sprint5.iid
      }
      expect(got).to eq(want)
    end
  end

  context 'Validations' do
    subject { build(:sprint, group: group, start_date: start_date, due_date: due_date) }

    describe '#dates_do_not_overlap' do
      let_it_be(:existing_sprint) { create(:sprint, group: group, start_date: 4.days.from_now, due_date: 1.week.from_now) }

      context 'when no Sprint dates overlap' do
        let(:start_date) { 2.weeks.from_now }
        let(:due_date) { 3.weeks.from_now }

        it { is_expected.to be_valid }
      end

      context 'when dates overlap' do
        context 'same group' do
          context 'when start_date is in range' do
            let(:start_date) { 5.days.from_now }
            let(:due_date) { 3.weeks.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end
          end

          context 'when end_date is in range' do
            let(:start_date) { Time.now }
            let(:due_date) { 6.days.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end
          end

          context 'when both overlap' do
            let(:start_date) { 5.days.from_now }
            let(:due_date) { 6.days.from_now }

            it 'is not valid' do
              expect(subject).not_to be_valid
              expect(subject.errors[:base]).to include('Dates cannot overlap with other existing Iterations')
            end
          end
        end

        context 'different group' do
          let(:start_date) { 5.days.from_now }
          let(:due_date) { 6.days.from_now }
          let(:group) { create(:group) }

          it { is_expected.to be_valid }
        end
      end
    end

    describe '#future_date' do
      context 'when dates are in the future' do
        let(:start_date) { Time.now }
        let(:due_date) { 1.week.from_now }

        it { is_expected.to be_valid }
      end

      context 'when start_date is in the past' do
        let(:start_date) { 1.week.ago }
        let(:due_date) { 1.week.from_now }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:start_date]).to include('cannot be in the past')
        end
      end

      context 'when due_date is in the past' do
        let(:start_date) { Time.now }
        let(:due_date) { 1.week.ago }

        it 'is not valid' do
          expect(subject).not_to be_valid
          expect(subject.errors[:due_date]).to include('cannot be in the past')
        end
      end
    end
  end

  describe '.within_timeframe' do
    let_it_be(:now) { Time.now }
    let_it_be(:project) { create(:project, :empty_repo) }
    let_it_be(:sprint_1) { create(:sprint, project: project, start_date: now, due_date: 1.day.from_now) }
    let_it_be(:sprint_2) { create(:sprint, project: project, start_date: 2.days.from_now, due_date: 3.days.from_now) }
    let_it_be(:sprint_3) { create(:sprint, project: project, start_date: 4.days.from_now, due_date: 1.week.from_now) }

    it 'returns sprints with start_date and/or end_date between timeframe' do
      sprints = described_class.within_timeframe(2.days.from_now, 3.days.from_now)

      expect(sprints).to match_array([sprint_2])
    end

    it 'returns sprints which starts before the timeframe' do
      sprints = described_class.within_timeframe(1.day.from_now, 3.days.from_now)

      expect(sprints).to match_array([sprint_1, sprint_2])
    end

    it 'returns sprints which ends after the timeframe' do
      sprints = described_class.within_timeframe(3.days.from_now, 5.days.from_now)

      expect(sprints).to match_array([sprint_2, sprint_3])
    end
  end
end
