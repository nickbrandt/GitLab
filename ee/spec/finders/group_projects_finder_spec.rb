require 'spec_helper'

describe GroupProjectsFinder do
  include_context 'GroupProjectsFinder context'

  subject { finder.execute }

  describe 'with an auditor current user' do
    let(:current_user) { create(:user, :auditor) }

    context 'only shared' do
      let(:options) { { only_shared: true } }

      it { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1]) }
    end

    context 'only owned' do
      let(:options) { { only_owned: true } }

      it { is_expected.to eq([private_project, public_project]) }
    end

    context 'all' do
      subject { described_class.new(group: group, current_user: current_user).execute }

      it { is_expected.to eq([shared_project_3, shared_project_2, shared_project_1, private_project, public_project]) }
    end
  end
end
