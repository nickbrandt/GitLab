# frozen_string_literal: true

require 'spec_helper'

describe Groups::ClustersController do
  include AccessMatchersForController

  set(:group) { create(:group) }

  let(:user) { create(:user) }

  before do
    group.add_maintainer(user)
    sign_in(user)
  end

  it_behaves_like 'cluster metrics' do
    let(:clusterable) { group }

    let(:cluster) do
      create(:cluster, :group, :provided_by_gcp, groups: [group])
    end

    let(:metrics_params) do
      {
        group_id: group,
        id: cluster
      }
    end
  end

  describe 'GET environments' do
    let(:cluster) { create(:cluster_for_group, groups: [group]) }

    before do
      create(:deployment, :success, cluster: cluster)
    end

    def go
      get :environments,
        params: {
          group_id: group.to_param,
          id: cluster
        },
        format: :json
    end

    describe 'functionality' do
      it 'responds successfully' do
        go

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'security' do
      it { expect { go }.to be_allowed_for(:admin) }
      it { expect { go }.to be_allowed_for(:owner).of(group) }
      it { expect { go }.to be_allowed_for(:maintainer).of(group) }
      it { expect { go }.to be_denied_for(:developer).of(group) }
      it { expect { go }.to be_denied_for(:reporter).of(group) }
      it { expect { go }.to be_denied_for(:guest).of(group) }
      it { expect { go }.to be_denied_for(:user) }
      it { expect { go }.to be_denied_for(:external) }
    end
  end
end
