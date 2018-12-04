# frozen_string_literal: true

require 'spec_helper'

describe GroupSamlIdentityFinder do
  include Gitlab::Routing

  let(:user) { create(:user) }
  let!(:identity) { create(:group_saml_identity, user: user) }
  let(:group) { identity.saml_provider.group }

  subject { described_class.new(user: user) }

  describe "#find_linked" do
    it "finds identity matching user and group" do
      expect(subject.find_linked(group: group)).to eq(identity)
    end

    it "returns nil when no saml_provider exists" do
      group.saml_provider.destroy!

      expect(subject.find_linked(group: group)).to eq(nil)
    end

    it "returns nil when group is nil" do
      expect(subject.find_linked(group: nil)).to eq(nil)
    end
  end

  describe "#all" do
    it "finds Group SAML identities for a user" do
      expect(subject.all.first).to eq(identity)
    end

    it "avoids N+1 on access to provider and group path" do
      identity = subject.all.first

      expect { group_path(identity.saml_provider.group) }.not_to exceed_query_limit(0)
    end
  end
end
