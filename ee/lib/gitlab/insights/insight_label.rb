# frozen_string_literal: true

module Gitlab
  module Insights
    class InsightLabel
      REGISTRY_KEY = :insight_labels_registry.freeze

      def self.registry
        Thread.current[REGISTRY_KEY] ||= {}
      end

      def self.clear_registry!
        Thread.current[REGISTRY_KEY] = {}
      end

      def self.[](title, color = nil)
        registry_key = title.to_s

        if registry.key?(registry_key)
          registry[registry_key].tap do |instance|
            instance.color = color if color
          end
        else
          registry[registry_key] = new(title, color)
        end
      end

      attr_reader :title
      attr_accessor :color

      def initialize(title, color = nil)
        @title = title
        @color = color
      end

      def inspect
        %(#<#{self.class.name} @title="#{title}", @color="#{color}">)
      end
    end
  end
end
