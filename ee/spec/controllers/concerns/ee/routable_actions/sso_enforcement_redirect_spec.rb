# frozen_string_literal: true

require 'spec_helper'

describe EE::RoutableActions::SsoEnforcementRedirect do
  let(:saml_provider) { create(:saml_provider, enforced_sso: true) }
  let(:root_group) { saml_provider.group }
  let(:nested_group) { create(:group, :private, parent: root_group) }
  let(:nested_project) { create(:project, :private, group: nested_group) }

  describe '#should_redirect_to_group_saml_sso?' do
    let(:user) { build_stubbed(:user) }
    let(:request) { double(:request, get?: true) }

    it 'returns false for User routables' do
      routable = build_stubbed(:user)

      subject = described_class.new(routable)

      expect(subject.should_redirect_to_group_saml_sso?(double, double)).to eq(false)
    end

    it 'returns false when routable is nil' do
      subject = described_class.new(nil)

      expect(subject.should_redirect_to_group_saml_sso?(double, double)).to eq(false)
    end

    context 'with a project' do
      subject { described_class.new(nested_project) }

      it 'is false when a new sso session is not needed' do
        allow_any_instance_of(ProjectPolicy).to receive(:needs_new_sso_session?).and_return(false)

        expect(subject.should_redirect_to_group_saml_sso?(user, request)).to eq false
      end

      it 'is true when a new sso session is needed' do
        allow_any_instance_of(ProjectPolicy).to receive(:needs_new_sso_session?).and_return(true)

        expect(subject.should_redirect_to_group_saml_sso?(user, request)).to eq true
      end

      context 'in a personal namespace' do
        subject { described_class.new(create(:project)) }

        it 'returns false' do
          expect(subject.should_redirect_to_group_saml_sso?(user, double)).to eq false
        end
      end
    end

    context 'with a group' do
      subject { described_class.new(nested_group) }

      it 'is false when a new sso session is not needed' do
        allow_any_instance_of(GroupPolicy).to receive(:needs_new_sso_session?).and_return(false)

        expect(subject.should_redirect_to_group_saml_sso?(user, request)).to eq false
      end

      it 'is true when a new sso session is needed' do
        allow_any_instance_of(GroupPolicy).to receive(:needs_new_sso_session?).and_return(true)

        expect(subject.should_redirect_to_group_saml_sso?(user, request)).to eq true
      end
    end
  end

  describe '#sso_redirect_url' do
    it 'returns the SSO url for a group' do
      subject = described_class.new(nested_group)

      expect(subject.sso_redirect_url).to match(/groups\/#{root_group.to_param}\/-\/saml\/sso\?token=/)
    end

    it "returns the SSO url for a project's root group" do
      subject = described_class.new(nested_project)

      expect(subject.sso_redirect_url).to match(/groups\/#{root_group.to_param}\/-\/saml\/sso\?token=/)
    end
  end
end
