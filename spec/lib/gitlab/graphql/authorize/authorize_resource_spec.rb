# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Authorize::AuthorizeResource do
  let(:fake_class) do
    Class.new do
      include Gitlab::Graphql::Authorize::AuthorizeResource

      attr_reader :user, :found_object

      authorize :read_the_thing

      def initialize(user, found_object)
        @user, @found_object = user, found_object
      end

      def find_object
        found_object
      end

      def current_user
        user
      end
    end
  end

  let(:user) { build(:user) }
  let(:project) { build(:project) }

  subject(:loading_resource) { fake_class.new(user, project) }

  context 'when the user is allowed to perform the action' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_the_thing, project, scope: :user) do
        true
      end
    end

    describe '#authorized_find!' do
      it 'returns the object' do
        expect(loading_resource.authorized_find!).to eq(project)
      end
    end

    describe '#authorize!' do
      it 'does not raise an error' do
        expect { loading_resource.authorize!(project) }.not_to raise_error
      end
    end

    describe '#authorized_resource?' do
      it 'is true' do
        expect(loading_resource.authorized_resource?(project)).to be(true)
      end
    end
  end

  context 'when the user is not allowed to perform the action' do
    before do
      allow(Ability).to receive(:allowed?).with(user, :read_the_thing, project, scope: :user) do
        false
      end
    end

    describe '#authorized_find!' do
      it 'raises an error' do
        expect { loading_resource.authorize!(project) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    describe '#authorize!' do
      it 'raises an error' do
        expect { loading_resource.authorize!(project) }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    describe '#authorized_resource?' do
      it 'is false' do
        expect(loading_resource.authorized_resource?(project)).to be(false)
      end
    end
  end

  context 'when the class does not define #find_object' do
    let(:fake_class) do
      Class.new { include Gitlab::Graphql::Authorize::AuthorizeResource }
    end

    it 'raises a comprehensive error message' do
      expect { fake_class.new.find_object }.to raise_error(/Implement #find_object in #{fake_class.name}/)
    end
  end

  context 'when the class does not define authorize' do
    let(:fake_class) do
      Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        attr_reader :user, :found_object

        def initialize(user, found_object)
          @user, @found_object = user, found_object
        end

        def find_object(*_args)
          found_object
        end

        def current_user
          user
        end

        def self.name
          'TestClass'
        end
      end
    end
    let(:error) { /#{fake_class.name} has no authorizations/ }

    describe '#authorized_find!' do
      it 'raises a comprehensive error message' do
        expect { loading_resource.authorized_find! }.to raise_error(error)
      end
    end

    describe '#authorized_resource?' do
      it 'raises a comprehensive error message' do
        expect { loading_resource.authorized_resource?(project) }.to raise_error(error)
      end
    end
  end

  describe '.authorize' do
    it 'adds permissions from subclasses to those of superclasses when used on classes' do
      base_class = Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorize :base_authorization
      end

      sub_class = Class.new(base_class) do
        authorize :sub_authorization
      end

      expect(base_class.required_permissions).to contain_exactly(:base_authorization)
      expect(sub_class.required_permissions)
        .to contain_exactly(:base_authorization, :sub_authorization)
    end
  end

  describe '.custom_authorize' do
    it 'calls the stored custom auth proc' do
      test_class = Class.new do
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorize do
          'authorization logic!'
        end
      end

      expect(test_class.custom_authorize).to eq('authorization logic!')
    end

    context 'when the custom auth depends on the object being authorized or current user' do
      it 'has access to the object and user' do
        test_class = Class.new do
          include Gitlab::Graphql::Authorize::AuthorizeResource

          authorize do |object, user|
            object.present? && user.present?
          end
        end

        expect(
          test_class.custom_authorize(double(:graphql_object), double(:current_user))
        ).to be_truthy
      end
    end
  end

  describe '.custom_authorize?' do
    context 'when there is a custom auth proc' do
      it 'returns true' do
        test_class = Class.new do
          include Gitlab::Graphql::Authorize::AuthorizeResource

          authorize do
            'authorization logic!'
          end
        end

        expect(test_class).to have_custom_authorization
      end
    end

    context 'when there is not a custom auth proc' do
      it 'returns false' do
        test_class = Class.new do
          include Gitlab::Graphql::Authorize::AuthorizeResource

          authorize :not_custom_auth
        end

        expect(test_class).not_to have_custom_authorization
      end
    end
  end

  describe '#authorize!' do
    let(:object_for_auth) { double(:graphql_object) }

    context 'when there is a custom authorization proc' do
      context 'when the custom auth returns true' do
        it 'allows access' do
          test_class = Class.new do
            include Gitlab::Graphql::Authorize::AuthorizeResource

            authorize { true }

            def current_user
              'user :)'
            end
          end

          expect { test_class.new.authorize!(object_for_auth) }.not_to raise_error
        end
      end

      context 'when the custom auth returns false' do
        it 'raises a resource not available error' do
          test_class = Class.new do
            include Gitlab::Graphql::Authorize::AuthorizeResource

            authorize { false }

            def current_user
              'user :)'
            end
          end

          expect { test_class.new.authorize!(object_for_auth) }.to raise_error(
            Gitlab::Graphql::Errors::ResourceNotAvailable
          )
        end
      end
    end
  end
end
