# frozen_string_literal: true

require "spec_helper"

describe EE::UserCalloutsHelper do
  describe '.show_gold_trial?' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:user_dismissed?).with(described_class::GOLD_TRIAL).and_return(false)
      allow(Gitlab).to receive(:com?).and_return(true)
      allow(Gitlab::Database).to receive(:read_only?).and_return(false)
      allow(user).to receive(:any_namespace_with_gold?).and_return(false)
      allow(user).to receive(:any_namespace_with_trial?).and_return(false)
    end

    it 'returns true when all conditions are met' do
      expect(helper.show_gold_trial?(user)).to be(true)
    end

    it 'returns false when there is no user record' do
      allow(helper).to receive(:current_user).and_return(nil)

      expect(helper.show_gold_trial?).to be(false)
    end
  end

  describe '.render_enable_hashed_storage_warning' do
    context 'when we should show the enable warning' do
      it 'renders the enable warning' do
        expect(helper).to receive(:show_enable_hashed_storage_warning?).and_return(true)

        expect(helper).to receive(:render_flash_user_callout)
          .with(:warning,
            /Please enable and migrate to hashed/,
            EE::UserCalloutsHelper::GEO_ENABLE_HASHED_STORAGE)

        helper.render_enable_hashed_storage_warning
      end
    end

    context 'when we should not show the enable warning' do
      it 'does not render the enable warning' do
        expect(helper).to receive(:show_enable_hashed_storage_warning?).and_return(false)

        expect(helper).not_to receive(:render_flash_user_callout)

        helper.render_enable_hashed_storage_warning
      end
    end
  end

  describe '.render_migrate_hashed_storage_warning' do
    context 'when we should show the migrate warning' do
      it 'renders the migrate warning' do
        expect(helper).to receive(:show_migrate_hashed_storage_warning?).and_return(true)

        expect(helper).to receive(:render_flash_user_callout)
          .with(:warning,
            /Please migrate all existing projects/,
            EE::UserCalloutsHelper::GEO_MIGRATE_HASHED_STORAGE)

        helper.render_migrate_hashed_storage_warning
      end
    end

    context 'when we should not show the migrate warning' do
      it 'does not render the migrate warning' do
        expect(helper).to receive(:show_migrate_hashed_storage_warning?).and_return(false)

        expect(helper).not_to receive(:render_flash_user_callout)

        helper.render_migrate_hashed_storage_warning
      end
    end
  end

  describe '.show_enable_hashed_storage_warning?' do
    subject { helper.show_enable_hashed_storage_warning? }
    let(:user) { create(:user) }

    before do
      expect(helper).to receive(:current_user).and_return(user)
    end

    context 'when the enable warning has not been dismissed' do
      context 'when hashed storage is disabled' do
        before do
          stub_application_setting(hashed_storage_enabled: false)
        end

        it { is_expected.to be_truthy }
      end

      context 'when hashed storage is enabled' do
        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when the enable warning was dismissed' do
      it 'does not render the enable warning' do
        create(:user_callout, user: user, feature_name: described_class::GEO_ENABLE_HASHED_STORAGE)

        expect(helper).not_to receive(:render_flash_user_callout)

        helper.render_enable_hashed_storage_warning
      end
    end
  end

  describe '.show_migrate_hashed_storage_warning?' do
    subject { helper.show_migrate_hashed_storage_warning? }
    let(:user) { create(:user) }

    before do
      expect(helper).to receive(:current_user).and_return(user)
    end

    context 'when the migrate warning has not been dismissed' do
      context 'when hashed storage is disabled' do
        before do
          expect(helper).to receive(:hashed_storage_enabled?).and_return(false)
        end

        it { is_expected.to be_falsy }
      end

      context 'when hashed storage is enabled' do
        before do
          expect(helper).to receive(:hashed_storage_enabled?).and_return(true)
        end

        context 'when there is a project in non-hashed-storage' do
          before do
            create(:project, :legacy_storage)
          end

          it { is_expected.to be_truthy }
        end

        context 'when there are NO projects in non-hashed-storage' do
          it { is_expected.to be_falsy }
        end
      end
    end

    context 'when the migrate warning was dismissed' do
      it 'does not render the migrate warning' do
        create(:user_callout, user: user, feature_name: described_class::GEO_ENABLE_HASHED_STORAGE)
        expect(helper).not_to receive(:render_flash_user_callout)

        helper.render_migrate_hashed_storage_warning
      end
    end
  end
end
