require 'spec_helper'

describe JobEntity do
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { double('request') }
  let(:entity) { described_class.new(job, request: request) }
  let(:environment) { create(:environment, project: project) }

  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  describe '#playable?' do
    let(:job) { create(:ci_build, :manual, project: project, environment: environment.name, ref: 'development') }

    context 'for protected environments' do
      let(:protected_environment) { create(:protected_environment, project: project, name: environment.name) }

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

          it { expect(subject[:playable]).to eq(result) }
        end
      end

      context 'when user has access to it' do
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

            protected_environment.deploy_access_levels.create(user: user)
          end

          it { expect(subject[:playable]).to eq(result) }
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

        it { expect(subject[:playable]).to eq(result) }
      end
    end
  end

  describe '#retryable?' do
    let(:job) { create(:ci_build, :failed, project: project, environment: environment.name, ref: 'development') }

    context 'for protected environments' do
      let(:protected_environment) { create(:protected_environment, project: project, name: environment.name) }

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

          it { expect(subject.include?(:retry_path)).to eq(result) }
        end
      end

      context 'when user has access to it' do
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

            protected_environment.deploy_access_levels.create(user: user)
          end

          it { expect(subject.include?(:retry_path)).to eq(result) }
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

        it { expect(subject.include?(:retry_path)).to eq(result) }
      end
    end
  end
end
