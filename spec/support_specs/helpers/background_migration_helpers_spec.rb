# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BackgroundMigrationHelpers do
  context 'with type: :background_migration metadata', type: :background_migration do
    it { expect(self).to respond_to :without_gitlab_reference }

    describe '#without_gitlab_reference' do
      context 'reference prohibited class' do
        it do
          exp_msg = "Prohibited reference to User class. Redefine within lib/gitlab/background_migration"
          expect do # rubocop: disable RSpec/VoidExpect
            without_gitlab_reference do
              User.object_id
            end.to raise_error(BackgroundMigrationHelpers::BackgroundMigrationError, exp_msg)
          end
        end
      end

      context 'reference permitted class' do
        let(:klass) { Class.new }

        it do
          expect do # rubocop: disable RSpec/VoidExpect
            without_gitlab_reference do
              Class
            end
          end.not_to raise_error
        end
      end
    end
  end

  context 'without type: :background_migration metadata' do
    it { expect(self).not_to respond_to :without_gitlab_reference }
  end
end
