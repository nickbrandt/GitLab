require 'rails_helper'

describe EnvironmentPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '#stop_environment' do
    let(:environment) { create(:environment, :with_review_app, ref: 'development', project: project) }

    subject { user.can?(:stop_environment, environment) }

    before do
      project.repository.add_branch(user, 'development', project.commit.id)
    end

    context 'when protected environment feature is not available' do
      where(:access_level, :result) do
        :guest      | false
        :reporter   | false
        :developer  | true
        :maintainer | true
        :admin      | true
      end

      with_them do
        before do
          allow(project).to receive(:feature_available?)
          .with(:protected_environments).and_return(false)

          if access_level == :admin
            user.update_attribute(:admin, true)
          elsif access_level.present?
            project.add_user(user, access_level)
          end
        end

        it { is_expected.to eq(result) }
      end
    end

    context 'when protected environment feature is available' do
      before do
        allow(project).to receive(:feature_available?)
          .with(:protected_environments).and_return(true)
      end

      context 'when environment is protected' do
        let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

        context 'when user does not have access to the environment' do
          where(:access_level, :result) do
            :guest      | false
            :reporter   | false
            :developer  | false
            :maintainer | false
            :admin      | true
          end

          with_them do
            before do
              protected_environment

              if access_level == :admin
                user.update_attribute(:admin, true)
              elsif access_level.present?
                project.add_user(user, access_level)
              end
            end

            it { is_expected.to eq(result) }
          end
        end

        context 'when user has access to the environment' do
          where(:access_level, :result) do
            :guest      | false
            :reporter   | false
            :developer  | false
            :maintainer | true
            :admin      | true
          end

          with_them do
            before do
              protected_environment.deploy_access_levels.create(user: user)

              if access_level == :admin
                user.update_attribute(:admin, true)
              elsif access_level.present?
                project.add_user(user, access_level)
              end
            end

            it { is_expected.to eq(result) }
          end
        end
      end

      context 'when environment is not protected' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | true
          :maintainer | true
          :admin      | true
        end

        with_them do
          before do
            if access_level == :admin
              user.update_attribute(:admin, true)
            elsif access_level.present?
              project.add_user(user, access_level)
            end
          end

          it { is_expected.to eq(result) }
        end
      end
    end
  end
end
