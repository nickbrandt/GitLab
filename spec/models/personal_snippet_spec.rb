# frozen_string_literal: true

require 'spec_helper'

describe PersonalSnippet do
  describe '#update_secret_snippet_data' do
    let!(:snippet) { create(:personal_snippet, :public, secret: secret) }
    let(:secret) { false }

    context 'when secret is false' do
      it 'does not update the secret_token' do
        expect(snippet.secret_token).to be_nil
      end
    end

    context 'when secret is true' do
      let(:secret) { true }

      it 'assigns a random hex value' do
        expect(snippet.secret_token).not_to be_nil
      end

      it 'does not overwrite existing secret_token' do
        expect do
          snippet.update(title: 'foobar')
        end.not_to change { snippet.secret_token }
      end

      context 'when the secret flag is disabled' do
        it 'sets the secret_token to nil' do
          expect do
            snippet.update(secret: false)
          end.to change { snippet.secret_token }.to(nil)
        end
      end

      context 'when the visibility_level changes to any other level' do
        it 'sets the secret_token to nil' do
          expect do
            snippet.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          end.to change { snippet.secret_token }.to(nil)
        end

        it 'disables the secret flag' do
          expect do
            snippet.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
          end.to change { snippet.secret }.to(false)
        end
      end
    end
  end

  describe '#snippet_can_be_secret?' do
    [
      { visibility: :public,   result: true },
      { visibility: :private,  result: false },
      { visibility: :internal, result: false }
    ].each do |combination|
      it 'returns true when snippet is public' do
        snippet = build(:personal_snippet, combination[:visibility])

        expect(snippet.send(:snippet_can_be_secret?)).to eq(combination[:result])
      end
    end
  end

  describe '#embeddable?' do
    [
      { snippet: :public,   embeddable: true },
      { snippet: :internal, embeddable: false },
      { snippet: :private,  embeddable: false }
    ].each do |combination|
      it 'returns true when snippet is public' do
        snippet = create(:personal_snippet, combination[:snippet])

        expect(snippet.embeddable?).to eq(combination[:embeddable])
      end
    end
  end

  describe '.visibility_level_values' do
    it 'includes secret visibility' do
      expect(described_class.visibility_level_values(nil))
        .to contain_exactly(Gitlab::VisibilityLevel::PRIVATE,
                            Gitlab::VisibilityLevel::INTERNAL,
                            Gitlab::VisibilityLevel::PUBLIC,
                            described_class::VISIBILITY_SECRET)
    end

    context 'when secret_snippets flag is disabled' do
      it 'includes secret visibility' do
        stub_feature_flags(secret_snippets: false)

        expect(described_class.visibility_level_values(nil))
          .to contain_exactly(Gitlab::VisibilityLevel::PRIVATE,
                              Gitlab::VisibilityLevel::INTERNAL,
                              Gitlab::VisibilityLevel::PUBLIC)
      end
    end
  end
end
