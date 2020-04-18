# frozen_string_literal: true

module Gitlab
  module Geo
    # Geo Replicators are objects that know how to replicate a replicable resource
    #
    # A replicator is responsible for:
    # - firing events (producer)
    # - consuming events (consumer)
    #
    # Each replicator is tied to a specific replicable resource
    class Replicator
      include ::Gitlab::Geo::LogHelpers

      attr_reader :model_record_id
      delegate :model, to: :class

      # Declare supported event
      #
      # @example Declaring support for :update and :delete events
      #   class MyReplicator < Gitlab::Geo::Replicator
      #     event :update
      #     event :delete
      #   end
      #
      # @param [Symbol] event_name
      def self.event(event_name)
        @events ||= []
        @events << event_name.to_sym
      end
      private_class_method :event

      # List supported events
      #
      # @return [Array<Symbol>] with list of events
      def self.supported_events
        @events.dup
      end

      # Check if the replicator supports a specific event
      #
      # @param [Symbol] event_name
      # @return [Boolean] whether event support was registered in the replicator
      def self.event_supported?(event_name)
        @events.include?(event_name.to_sym)
      end

      # Return the name of the replicable, e.g. "package_file"
      #
      # This can be used to retrieve the replicator class again
      # by using the `.for_replicable_name` method
      #
      # @see .for_replicable_name
      # @return [String] slug that identifies this replicator
      def self.replicable_name
        self.name.demodulize.sub('Replicator', '').underscore
      end

      # Return the registry related to the replicable resource
      #
      # @return [Class<Geo::BaseRegistry>] registry class
      def self.registry_class
        const_get("::Geo::#{replicable_name.camelize}Registry", false)
      end

      # Given a `replicable_name`, return the corresponding replicator
      #
      # @param [String] replicable_name the replicable slug
      # @return [Class<Geo::Replicator>] replicator implementation
      def self.for_replicable_name(replicable_name)
        replicator_class_name = "::Geo::#{replicable_name.camelize}Replicator"

        const_get(replicator_class_name, false)
      end

      def self.checksummed
        model.checksummed
      end

      def self.checksummed_count
        model.checksummed.count
      end

      def self.checksum_failed_count
        model.checksum_failed.count
      end

      def self.primary_total_count
        model.count
      end

      # @param [ActiveRecord::Base] model_record
      # @param [Integer] model_record_id
      def initialize(model_record: nil, model_record_id: nil)
        @model_record = model_record
        @model_record_id = model_record_id
      end

      # Instance of the replicable model
      #
      # @return [ActiveRecord::Base, nil]
      # @raise ActiveRecord::RecordNotFound when a model with specified model_record_id can't be found
      def model_record
        if defined?(@model_record) && @model_record
          return @model_record
        end

        if model_record_id
          @model_record = model.find(model_record_id)
        end
      end

      # Publish an event with its related data
      #
      # @param [Symbol] event_name
      # @param [Hash] event_data
      def publish(event_name, **event_data)
        return unless Feature.enabled?(:geo_self_service_framework)

        raise ArgumentError, "Unsupported event: '#{event_name}'" unless self.class.event_supported?(event_name)

        create_event_with(
          class_name: ::Geo::Event,
          replicable_name: self.class.replicable_name,
          event_name: event_name,
          payload: event_data
        )
      end

      # Consume an event, using the published contextual data
      #
      # This method is called by the GeoLogCursor when reading the event from the queue
      #
      # @param [Symbol] event_name
      # @param [Hash] event_data contextual data published with the event
      def consume(event_name, **event_data)
        raise ArgumentError, "Unsupported event: '#{event_name}'" unless self.class.event_supported?(event_name)

        consume_method = "consume_event_#{event_name}".to_sym
        raise NotImplementedError, "Consume method not implemented: '#{consume_method}'" unless self.methods.include?(consume_method)

        # Inject model_record based on included class
        if model_record
          event_data[:model_record] = model_record
        end

        send(consume_method, **event_data) # rubocop:disable GitlabSecurity/PublicSend
      end

      # Return the name of the replicator
      #
      # @return [String] slug that identifies this replicator
      def replicable_name
        self.class.replicable_name
      end

      # Return the registry related to the replicable resource
      #
      # @return [Class<Geo::BaseRegistry>] registry class
      def registry_class
        self.class.registry_class
      end

      # Return registry instance scoped to current model
      #
      # @return [Geo::BaseRegistry] registry instance
      def registry
        registry_class.for_model_record_id(model_record.id)
      end

      # Checksum value from the main database
      #
      # @abstract
      def primary_checksum
        nil
      end

      protected

      # Store an event on the database
      #
      # @example Create an event
      #   create_event_with(class_name: Geo::CacheInvalidationEvent, key: key)
      #
      # @param [Class] class_name a ActiveRecord class that's used to store an event for Geo
      # @param [Hash] **params context information that will be stored in the event table
      # @return [ApplicationRecord] event instance that was just persisted
      def create_event_with(class_name:, **params)
        return unless Gitlab::Geo.primary?
        return unless Gitlab::Geo.secondary_nodes.any?

        event = class_name.create!(**params)

        # Only works with the new geo_events at the moment because we need to
        # know which foreign key to use
        ::Geo::EventLog.create!(geo_event: event)

        event
      rescue ActiveRecord::RecordInvalid, NoMethodError => e
        log_error("#{class_name} could not be created", e, params)
      end
    end
  end
end
