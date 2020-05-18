# frozen_string_literal: true

RSpec.shared_examples 'protected environments access' do |developer_access = true|
  using RSpec::Parameterized::TableSyntax

  include AdminModeHelper

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:protected_environments).and_return(feature_available)
  end

  context 'when Protected Environments feature is not available in the project' do
    let(:feature_available) { false }

    where(:access_level, :admin_mode, :result) do
      :guest      | nil   | false
      :reporter   | nil   | false
      :developer  | nil   | developer_access
      :maintainer | nil   | true
      :admin      | false | false
      :admin      | true  | true
    end

    with_them do
      before do
        environment

        update_user_access(access_level, admin_mode, user, project)
      end

      it { is_expected.to eq(result) }
    end
  end

  context 'when Protected Environments feature is available in the project' do
    let(:feature_available) { true }

    context 'when environment is protected' do
      let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

      context 'when user does not have access to the environment' do
        where(:access_level, :admin_mode, :result) do
          :guest      | nil   | false
          :reporter   | nil   | false
          :developer  | nil   | false
          :maintainer | nil   | false
          :admin      | false | false
          :admin      | true  | true
        end

        with_them do
          before do
            protected_environment

            update_user_access(access_level, admin_mode, user, project)
          end

          it { is_expected.to eq(result) }
        end
      end

      context 'when user has access to the environment' do
        where(:access_level, :admin_mode, :result) do
          :guest      | nil   | false
          :reporter   | nil   | false
          :developer  | nil   | developer_access
          :maintainer | nil   | true
          :admin      | false | false
          :admin      | true  | true
        end

        with_them do
          before do
            protected_environment.deploy_access_levels.create(user: user)

            update_user_access(access_level, admin_mode, user, project)
          end

          it { is_expected.to eq(result) }
        end
      end
    end

    context 'when environment is not protected' do
      where(:access_level, :admin_mode, :result) do
        :guest      | nil   | false
        :reporter   | nil   | false
        :developer  | nil   | developer_access
        :maintainer | nil   | true
        :admin      | false | false
        :admin      | true  | true
      end

      with_them do
        before do
          update_user_access(access_level, admin_mode, user, project)
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  def update_user_access(access_level, admin_mode, user, project)
    if access_level == :admin
      user.update_attribute(:admin, true)
      enable_admin_mode!(user) if admin_mode
    elsif access_level.present?
      project.add_user(user, access_level)
    end
  end
end
