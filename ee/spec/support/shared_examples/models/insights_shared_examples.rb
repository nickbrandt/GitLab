# This needs an `entity` object: Project or Group.
RSpec.shared_examples 'an entity with the Insights feature' do
  before do
    # This is needed because all feature flags are enabled by default in tests
    allow(Feature).to receive(:enabled?)
      .with(:insights, entity)
      .and_return(false)
  end

  context 'when license does not allow it' do
    before do
      stub_licensed_features(insights: false)
    end

    it { expect(entity).not_to be_insights_available }

    context 'when the feature flag is enabled globally' do
      before do
        stub_feature_flags(insights: true)
      end

      it { expect(entity).not_to be_insights_available }
    end

    context 'when the feature flag is enabled for the entity' do
      before do
        stub_feature_flags(insights: { enabled: true, thing: entity })
      end

      it { expect(entity).not_to be_insights_available }
    end
  end

  context 'when license allows it' do
    before do
      stub_licensed_features(insights: true)
    end

    it { expect(entity).not_to be_insights_available }

    context 'when the feature flag is disabled globally' do
      before do
        stub_feature_flags(insights: false)
      end

      it { expect(entity).not_to be_insights_available }
    end

    context 'when the feature flag is enabled globally' do
      before do
        stub_feature_flags(insights: true)
      end

      it { expect(entity).to be_insights_available }
    end

    context 'when the feature flag is enabled for the entity' do
      before do
        stub_feature_flags(insights: { enabled: true, thing: entity })
      end

      it { expect(entity).to be_insights_available }
    end
  end
end
