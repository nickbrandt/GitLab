# frozen_string_literal: true

module Gitlab
  module Ci
    class Jwt < JSONWebToken::RSAToken
      include Gitlab::Utils::StrongMemoize

      DEFAULT_EXPIRE_TIME = 5.minutes.to_i

      def self.for_build(build)
        self.new(build, ttl: build.metadata_timeout).encoded
      end

      def initialize(build, ttl: nil)
        super(nil)

        @build = build
        @key_data = Rails.application.secrets.openid_connect_signing_key

        # Reserved claims
        self.issuer = Settings.gitlab.host
        self.issued_at = Time.now
        self.expire_time = issued_at + (ttl || DEFAULT_EXPIRE_TIME)
        self.subject = "job_#{build.id}"

        # Custom claims
        self[:namespace_id] = namespace.id.to_s
        self[:namespace_path] = namespace.full_path
        self[:project_id] = project.id.to_s
        self[:project_path] = project.full_path
        self[:user_id] = user&.id.to_s
        self[:user_login] = user&.username
        self[:user_email] = user&.email
        self[:pipeline_id] = build.pipeline.id.to_s
        self[:job_id] = build.id.to_s
        self[:ref] = source_ref
        self[:ref_type] = ref_type
        self[:ref_protected] = build.protected.to_s
      end

      private

      attr_reader :build, :key_data

      def kid
        public_key.to_jwk[:kid]
      end

      def project
        build.project
      end

      def namespace
        project.namespace
      end

      def user
        build.user
      end

      def source_ref
        build.pipeline.source_ref
      end

      def ref_type
        ::Ci::BuildRunnerPresenter.new(build).ref_type
      end
    end
  end
end
