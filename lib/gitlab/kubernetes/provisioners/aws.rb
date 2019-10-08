# frozen_string_literal: true

module Gitlab
  module Kubernetes
    module Provisioners
      class Aws
        include Gitlab::Utils::StrongMemoize

        delegate :account_id, :access_key_id, :secret_access_key, to: :config, allow_nil: true

        private

        def config
          strong_memoize(:config) do
            Gitlab.config.kubernetes.provisioners.aws
          rescue Settingslogic::MissingSetting
            # no-op
          end
        end
      end
    end
  end
end
