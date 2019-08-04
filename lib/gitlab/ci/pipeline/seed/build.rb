# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :dig, to: :@attributes

          def initialize(pipeline, attributes)
            @pipeline = pipeline
            @attributes = attributes

            @only = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:only))
            @except = Gitlab::Ci::Build::Policy
              .fabricate(attributes.delete(:except))
          end

          def included?
            strong_memoize(:inclusion) do
              @only.all? { |spec| spec.satisfied_by?(@pipeline, self) } &&
                @except.none? { |spec| spec.satisfied_by?(@pipeline, self) }
            end
          end

          def attributes
            @attributes.merge(
              pipeline: @pipeline,
              project: @pipeline.project,
              user: @pipeline.user,
              ref: @pipeline.ref,
              tag: @pipeline.tag,
              trigger_request: @pipeline.legacy_trigger,
              protected: @pipeline.protected_ref?
            )
          end

          def bridge?
            attributes_hash = @attributes.to_h
            attributes_hash.dig(:options, :trigger).present? ||
              (attributes_hash.dig(:options, :bridge_needs).instance_of?(Hash) &&
               attributes_hash.dig(:options, :bridge_needs, :pipeline).present?)
          end

          def to_resource
            strong_memoize(:resource) do
              if bridge?
                ::Ci::Bridge.new(attributes)
              else
                ::Ci::Build.new(attributes)
              end
            end
          end
        end
      end
    end
  end
end
