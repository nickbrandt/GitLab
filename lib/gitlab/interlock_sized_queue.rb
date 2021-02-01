# frozen_string_literal: true

module Gitlab
  class InterlockSizedQueue < SizedQueue
    extend ::Gitlab::Utils::Override

    override :pop
    def pop(*)
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        super
      end
    end

    override :push
    def push(*)
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        super
      end
    end

    override :close
    def close(*)
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        super
      end
    end
  end
end
