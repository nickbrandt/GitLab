# frozen_string_literal: true

require 'spec_helper'

describe PersonalSnippet do
  describe '#update_secret_token' do
    let(:snippet) { create(:personal_snippet, :public) }

    context 'visibility_level is NOT SECRET' do
      it 'does not update the secret_token' do
        expect(snippet.secret_token).to be_nil
      end
    end

    context 'visibility_level is SECRET' do
      let(:snippet) { create(:personal_snippet, :secret) }

      it 'assigns a random hex value' do
        expect(snippet.secret_token).not_to be_nil
      end

      context 'when the visibility_level changes to any other level' do
        it 'sets the secret_token to nil' do
          snippet.visibility_level = Gitlab::VisibilityLevel::PUBLIC
          snippet.save

          expect(snippet.secret_token).to be_nil
        end
      end
    end
  end

  describe '#visibility_secret?' do
    let(:snippet) { create(:personal_snippet, :public) }

    context 'when snippet visibility is not Secret' do
      it 'returns false' do
        expect(snippet.visibility_secret?).to be_falsey
      end
    end

    context 'when snippet visibility is Secret' do
      let(:snippet) { create(:personal_snippet, :secret) }

      it 'returns true' do
        expect(snippet.visibility_secret?).to be_truthy
      end
    end
  end

  describe '#secret?' do
    let(:snippet) { create(:personal_snippet, :public) }

    context 'when snippet visibility is not Secret' do
      it 'returns false' do
        expect(snippet.secret?).to be_falsey
      end
    end

    context 'when snippet visibility is Secret' do
      let(:snippet) { create(:personal_snippet, :secret) }

      it 'returns true' do
        expect(snippet.secret?).to be_truthy
      end

      context 'when secret_token is empty' do
        let(:snippet) { create(:personal_snippet, :public) }

        it 'returns false' do
          snippet.update_column(:visibility_level, Gitlab::VisibilityLevel::SECRET)

          expect(snippet.visibility_secret?).to be_truthy
          expect(snippet.secret?).to be_falsey
        end
      end
    end
  end

  describe '#embeddable?' do
    [
      { snippet: :public,   embeddable: true,  secret_token: nil },
      { snippet: :internal, embeddable: false, secret_token: nil },
      { snippet: :private,  embeddable: false, secret_token: nil }
    ].each do |combination|
      it 'returns true when snippet is public' do
        snippet = create(:personal_snippet, combination[:snippet], secret_token: combination[:secret_token])

        expect(snippet.embeddable?).to eq(combination[:embeddable])
      end
    end

    context 'when visibility_level is Secret' do
      let(:snippet) { create(:personal_snippet, :secret) }

      it 'returns true' do
        expect(snippet.embeddable?).to be_truthy
      end

      context 'when secret_token is not present' do
        let(:snippet) { create(:personal_snippet, :public) }

        it 'returns false' do
          snippet.update_column(:visibility_level, Gitlab::VisibilityLevel::SECRET)

          expect(snippet.embeddable?).to be_falsey
        end
      end
    end
  end
end
