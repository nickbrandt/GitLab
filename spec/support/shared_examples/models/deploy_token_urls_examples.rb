# frozen_string_literal: true

RSpec.shared_examples 'deploy token accessible model' do
  describe '#deploy_token_create_url' do
    let(:options) { {} }
    let(:create_token_path) { "create_deploy_token_#{entity.class.name.downcase}_settings_ci_cd_path" }

    subject { entity.deploy_token_create_url(options) }

    it 'returns the right path' do
      expect(subject).to eq(Gitlab::Routing.url_helpers.send(create_token_path, entity, options))
    end

    context 'when some options are passed in' do
      let(:options) { { key: 'value' } }

      it 'returns the right path' do
        expect(subject).to eq(Gitlab::Routing.url_helpers.send(create_token_path, entity, options))
      end
    end
  end

  describe '#deploy_token_revoke_url_for' do
    let(:token) { create(:deploy_token) }
    let(:revoke_path) { "revoke_#{entity.class.name.downcase}_deploy_token_path" }

    subject { entity.deploy_token_revoke_url_for(token) }

    it 'returns the right path' do
      expect(subject).to eq(Gitlab::Routing.url_helpers.send(revoke_path, entity, token))
    end
  end
end
