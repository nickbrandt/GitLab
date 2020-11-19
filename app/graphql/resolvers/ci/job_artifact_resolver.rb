# frozen_string_literal: true

module Resolvers
  module Ci
    class JobArtifactResolver < BaseResolver
      argument :types, [Types::JobArtifactTypeEnum],
        required: false,
        description: '...'

      def resolve(types: [])
        [ {download_path: "https://some.url/#{object.id}" } ]
      end
    end
  end
end
