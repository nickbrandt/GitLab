# frozen_string_literal: true

shared_examples_for 'cycle analytics stage' do
  let(:valid_params) do
    {
      name: 'My Stage',
      parent: parent,
      start_event_identifier: :issue_created,
      end_event_identifier: :issue_closed
    }
  end

  describe 'validation' do
    it 'is valid' do
      expect(described_class.new(valid_params)).to be_valid
    end

    it 'is invalid when end_event is not allowed for the given start_event' do
      invalid_params = valid_params.merge(
        start_event_identifier: :issue_closed,
        end_event_identifier: :issue_created
      )
      stage = described_class.new(invalid_params)

      expect(stage).not_to be_valid
      expect(stage.errors.details[:end_event]).to eq([{ error: :not_allowed_for_the_given_start_event }])
    end
  end

  describe '#subject_model' do
    it 'infers the model to be queried from the start event' do
      stage = described_class.new(valid_params)

      expect(stage.subject_model).to eq(Issue)
    end
  end
end
