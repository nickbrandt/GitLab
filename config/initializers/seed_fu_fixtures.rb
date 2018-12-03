# frozen_string_literal: true
# Include EE-only fixtures into seed_fu
SeedFu.fixture_paths.push("#{Rails.root}/ee/db/fixtures/#{Rails.env}")
