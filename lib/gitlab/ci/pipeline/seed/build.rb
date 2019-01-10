# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        ## TODO this should become Seed::Job now
        #
        class Build < Seed::Base
          include Gitlab::Utils::StrongMemoize

          delegate :dig, to: :@attributes

          def initialize(pipeline, attributes)
            @pipeline = pipeline
            @attributes = attributes

            # TODO we should extract that
            @type = attributes.dig(:options, :trigger) ? ::Ci::Bridge : ::Ci::Build

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
            ).compact
          end

          def to_resource
            strong_memoize(:resource) { @type.new(attributes) }
          end
        end
      end
    end
  end
end
