# frozen_string_literal: true

require 'spec_helper'

describe 'ee/bin/sidekiq-cluster' do
  using RSpec::Parameterized::TableSyntax

  where(:args, :included, :excluded) do
    %w[--negate cronjob] | '-qdefault,1' | '-qcronjob,1'
    %w[--experimental-queue-selector resource_boundary=cpu] | '-qupdate_merge_requests,1' | '-qdefault,1'
  end

  with_them do
    it 'runs successfully', :aggregate_failures do
      cmd = %w[ee/bin/sidekiq-cluster --dryrun] + args

      output, status = Gitlab::Popen.popen(cmd, Rails.root.to_s)

      expect(status).to be(0)
      expect(output).to include('"bundle", "exec", "sidekiq"')
      expect(output).to include(included)
      expect(output).not_to include(excluded)
    end
  end
end
