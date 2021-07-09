# frozen_string_literal: true

shared_examples 'a model with a requirement issue association' do
  describe 'requirement issue association' do
    subject { build(:requirement, requirement_issue: requirement_issue_arg) }

    let(:requirement_issue) { build(:requirement_issue) }

    context 'when the requirement issue is of type requirement' do
      let(:requirement_issue_arg) { requirement_issue }

      specify { expect(subject).to be_valid }
    end

    context 'when requirement issue is not of requirement type' do
      let(:invalid_issue) { create(:issue) }
      let(:requirement_issue_arg) { invalid_issue }

      specify do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:requirement_issue]).to include(/must be a `requirement`/)
      end

      context 'when requirement issue is invalid but the type field is not dirty' do
        let(:requirement_arg) { nil }
        let(:requirement_issue_arg) { requirement_issue }

        before do
          subject.save!

          # simulate the issue type changing in the background, which will be allowed
          # the state is technically "invalid" (there are test reports associated with a non-requirement issue)
          # but we don't want to prevent updating other fields
          requirement_issue.update_attribute(:issue_type, :incident)
        end

        specify do
          expect(subject).to be_valid
        end

        it { is_expected.to be_valid }
      end
    end
  end
end
