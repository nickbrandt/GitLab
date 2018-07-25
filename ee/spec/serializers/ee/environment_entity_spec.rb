require 'spec_helper'

describe EnvironmentEntity do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project) }

  let(:entity) do
    described_class.new(environment, request: double(current_user: user, project: project))
  end

  describe '#protected?' do
    subject { entity.as_json[:is_protected] }

    context 'when environment is protected' do
      before do
        create(:protected_environment, name: environment.name, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when environment is not protected' do
      it { is_expected.to be_falsy }
    end
  end

  describe '#can_deploy?' do
    subject { entity.as_json[:can_deploy] }

    context 'for protected environments' do
      let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

      context 'when user does not have access to it' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
          :maintainer | false
          :admin      | true
        end

        with_them do
          before do
            if access_level == :admin
              user.update_attribute(:admin, true)
            elsif access_level.present?
              project.add_user(user, access_level)
            end

            protected_environment
          end

          it { is_expected.to eq(result) }
        end
      end

      context 'when user has access to it' do
        where(:access_level, :result) do
          :guest      | true
          :reporter   | true
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

            protected_environment.deploy_access_levels.create(user: user)
          end

          it { is_expected.to eq(result) }
        end
      end
    end

    context 'for unprotected environments' do
      where(:access_level, :result) do
        :guest      | true
        :reporter   | true
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

  describe '#can_stop' do
    let(:environment) { create(:environment, :with_review_app, ref: 'development', project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    before do
      project.repository.add_branch(user, 'development', project.commit.id)
    end

    subject { entity.as_json[:can_stop] }

    context 'for protected environments' do
      let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

      context 'when user does not have access to it' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
          :maintainer | false
          :admin      | true
        end

        with_them do
          before do
            if access_level == :admin
              user.update_attribute(:admin, true)
            elsif access_level.present?
              project.add_user(user, access_level)
            end

            protected_environment
          end

          it { is_expected.to eq(result) }
        end
      end

      context 'when user has access to it' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
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

            protected_environment.deploy_access_levels.create(user: user)
          end

          it { is_expected.to eq(result) }
        end
      end
    end

    context 'for unprotected environments' do
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

  describe '#terminal_path' do
    subject { entity.as_json }

    context 'for protected environments' do
      let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

      context 'when user does not have access to it' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
          :maintainer | false
          :admin      | true
        end

        with_them do
          before do
            allow(environment).to receive(:has_terminals?).and_return(true)

            if access_level == :admin
              user.update_attribute(:admin, true)
            elsif access_level.present?
              project.add_user(user, access_level)
            end

            protected_environment
          end

          it { expect(subject.include?(:terminal_path)).to eq(result) }
        end
      end

      context 'when user has access to it' do
        where(:access_level, :result) do
          :guest      | false
          :reporter   | false
          :developer  | false
          :maintainer | true
          :admin      | true
        end

        with_them do
          before do
            allow(environment).to receive(:has_terminals?).and_return(true)

            if access_level == :admin
              user.update_attribute(:admin, true)
            elsif access_level.present?
              project.add_user(user, access_level)
            end

            protected_environment.deploy_access_levels.create(user: user)
          end

          it { expect(subject.include?(:terminal_path)).to eq(result) }
        end
      end
    end

    context 'for unprotected environments' do
      where(:access_level, :result) do
        :guest      | false
        :reporter   | false
        :developer  | false
        :maintainer | true
        :admin      | true
      end

      with_them do
        before do
          allow(environment).to receive(:has_terminals?).and_return(true)

          if access_level == :admin
            user.update_attribute(:admin, true)
          elsif access_level.present?
            project.add_user(user, access_level)
          end
        end

        it { expect(subject.include?(:terminal_path)).to eq(result) }
      end
    end
  end
end
