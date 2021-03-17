# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'pages storage check' do
  let(:main_error_message) { "Please enable at least one of the two Pages storage strategy (local_store or object_store) in your config/gitlab.yml - set their 'enabled' attribute to true." }

  subject(:initializer) { load Rails.root.join('config/initializers/pages_storage_check.rb') }

  context 'when the pages_update_legacy_storage FF is turned on' do
    before do
      stub_feature_flags(pages_update_legacy_storage: true)
    end

    it { is_expected.to be_truthy }
  end

  context 'when the pages_update_legacy_storage FF is turned false' do
    before do
      stub_feature_flags(pages_update_legacy_storage: false)
    end

    context 'when pages is not enabled' do
      before do
        Settings.pages['enabled'] = false
      end

      it { is_expected.to be_truthy }
    end

    context 'when pages is enabled' do
      before do
        Settings.pages['enabled'] = true
      end

      context 'when pages object storage is not enabled' do
        before do
          Settings.pages['object_store']['enabled'] = false
        end

        context 'when pages local storage is not enabled' do
          it 'raises an exception' do
            Settings.pages['local_store']['enabled'] = false

            expect { subject }.to raise_error(main_error_message)
          end
        end

        context 'when pages local storage is enabled' do
          it 'is true' do
            Settings.pages['local_store']['enabled'] = true

            expect(subject).to be_truthy
          end
        end
      end

      context 'when pages object storage is enabled' do
        before do
          Settings.pages['object_store']['enabled'] = true
        end

        context 'when pages local storage is not enabled' do
          it 'is true' do
            Settings.pages['local_store']['enabled'] = false

            expect(subject).to be_truthy
          end
        end

        context 'when pages local storage is enabled' do
          it 'is true' do
            Settings.pages['local_store']['enabled'] = true

            expect(subject).to be_truthy
          end
        end
      end

      context 'when enabled attributes are set with a character instead of a boolean' do
        it 'raises an exception' do
          Settings.pages['local_store']['enabled'] = 0

          expect { subject }.to raise_error("Please set either true or false for pages:local_store:enabled setting.")
        end
      end

      context 'when both enabled attributes are not set' do
        it 'raises an exception' do
          Settings.pages['local_store']['enabled'] = nil
          Settings.pages['object_store']['enabled'] = nil

          expect { subject }.to raise_error(main_error_message)
        end
      end
    end
  end
end
