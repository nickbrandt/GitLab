# frozen_string_literal: true

require 'spec_helper'

describe ScimFinder do
  let(:group) { create(:group) }
  let(:unused_params) { double }

  subject(:finder) { described_class.new(group) }

  describe '#search' do
    context 'without a SAML provider' do
      it 'returns an empty relation when there is no saml provider' do
        expect(finder.search(unused_params)).to eq Identity.none
      end
    end

    context 'SCIM/SAML is not enabled' do
      before do
        create(:saml_provider, group: group, enabled: false)
      end

      it 'returns an empty relation when SCIM/SAML is not enabled' do
        expect(finder.search(unused_params)).to eq Identity.none
      end
    end

    context 'with SCIM enabled' do
      let!(:saml_provider) { create(:saml_provider, group: group) }

      context 'with an eq filter' do
        let!(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
        let!(:other_identity) { create(:group_saml_identity, saml_provider: saml_provider) }

        it 'allows identity lookup by id/externalId' do
          expect(finder.search(filter: "id eq #{identity.extern_uid}")).to be_a ActiveRecord::Relation
          expect(finder.search(filter: "id eq #{identity.extern_uid}").first).to eq identity
          expect(finder.search(filter: "externalId eq #{identity.extern_uid}").first).to eq identity
        end
      end

      it 'returns all related identities if there is no filter' do
        create_list(:group_saml_identity, 2, saml_provider: saml_provider)

        expect(finder.search({}).count).to eq 2
      end

      it 'raises an error if the filter is unsupported' do
        expect { finder.search(filter: 'id ne 1').count }.to raise_error(ScimFinder::UnsupportedFilter)
      end

      it 'raises an error if the attribute path is unsupported' do
        expect { finder.search(filter: 'userName eq "name"').count }.to raise_error(ScimFinder::UnsupportedFilter)
      end
    end
  end
end
