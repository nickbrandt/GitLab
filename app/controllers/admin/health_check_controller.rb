# frozen_string_literal: true

class Admin::HealthCheckController < Admin::ApplicationController
  def show
<<<<<<< HEAD
    checks = ['standard']
    checks << 'geo' if Gitlab::Geo.secondary?

    @errors = HealthCheck::Utils.process_checks(checks)
=======
    @errors = HealthCheck::Utils.process_checks(['standard'])
>>>>>>> upstream/master
  end
end
