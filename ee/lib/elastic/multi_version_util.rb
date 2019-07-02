# frozen_string_literal: true

module Elastic
  module MultiVersionUtil
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    attr_reader :data_class, :data_target

    # @params version [String, Module] can be a string "V12p1" or module (Elastic::V12p1)
    def version(version)
      version = Elastic.const_get(version) if version.is_a?(String)
      version.const_get(proxy_class_name).new(data_target)
    end

    private

    # TODO: load from db table https://gitlab.com/gitlab-org/gitlab-ee/issues/12555
    def elastic_reading_target
      strong_memoize(:elastic_reading_target) do
        version('V12p1')
      end
    end

    # TODO: load from db table https://gitlab.com/gitlab-org/gitlab-ee/issues/12555
    def elastic_writing_targets
      strong_memoize(:elastic_writing_targets) do
        [elastic_reading_target]
      end
    end

    def get_data_class(klass)
      klass < ActiveRecord::Base ? klass.base_class : klass
    end

    def generate_forwarding
      write_methods = elastic_writing_targets.first.real_class.write_methods

      write_methods.each do |method|
        self.class.forward_write_method(method)
      end

      read_methods = elastic_reading_target.real_class.public_instance_methods
      read_methods -= write_methods
      read_methods -= self.class.instance_methods
      read_methods.delete(:method_missing)

      read_methods.each do |method|
        self.class.forward_read_method(method)
      end
    end

    class_methods do
      def forward_read_method(method)
        return if respond_to?(method)

        delegate method, to: :elastic_reading_target
      end

      def forward_write_method(method)
        return if respond_to?(method)

        define_method(method) do |*args|
          responses = elastic_writing_targets.map do |elastic_target|
            elastic_target.public_send(method, *args) # rubocop:disable GitlabSecurity/PublicSend
          end

          responses.find { |response| response['_shards']['successful'] == 0 } || responses.last
        end
      end
    end
  end
end
