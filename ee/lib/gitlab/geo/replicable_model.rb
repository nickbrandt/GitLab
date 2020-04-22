# frozen_string_literal: true

module Gitlab
  module Geo
    module ReplicableModel
      extend ActiveSupport::Concern
      include Checksummable

      included do
        # If this hook turns out not to apply to all Models, perhaps we should extract a `ReplicableBlobModel`
        after_create_commit -> { replicator.handle_after_create_commit if replicator.respond_to?(:handle_after_create_commit) }

        scope :checksummed, -> { where('verification_checksum IS NOT NULL') }
        scope :checksum_failed, -> { where('verification_failure IS NOT NULL') }
      end

      class_methods do
        def with_replicator(klass)
          raise ArgumentError, 'Must be a class inheriting from Gitlab::Geo::Replicator' unless klass < ::Gitlab::Geo::Replicator

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            define_method :replicator do
              @_replicator ||= klass.new(model_record: self)
            end
          RUBY
        end
      end

      # Geo Replicator
      #
      # @return [Gitlab::Geo::Replicator]
      def replicator
        raise NotImplementedError, 'There is no Replicator defined for this model'
      end

      def calculate_checksum!
        self.verification_checksum = nil

        return unless needs_checksum?

        self.verification_checksum = self.class.hexdigest(file.path)
      end

      def needs_checksum?
        verification_checksum.nil? && checksummable?
      end

      def checksummable?
        local? && file_exist?
      end

      # This checks for existence of the file on storage
      #
      # @return [Boolean] whether the file exists on storage
      def file_exist?
        if local?
          File.exist?(file.path)
        else
          file.exists?
        end
      end
    end
  end
end
