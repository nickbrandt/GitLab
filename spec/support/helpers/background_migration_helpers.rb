# frozen_string_literal: true

module BackgroundMigrationHelpers
  BackgroundMigrationError = Class.new(StandardError)

  def without_gitlab_reference(&blk)
    tp = TracePoint.new(:call) do |tp|
      if prohibited?(tp.defined_class)
        msg = "Prohibited reference to #{tp.defined_class} class. Redefine within lib/gitlab/background_migration"
        raise BackgroundMigrationError.new(msg)
      end
    end

    tp.enable(&blk)
  end

  private

  def prohibited?(klass)
    klass < ApplicationRecord &&
    !klass.name.starts_with?('Gitlab::BackgroundMigration')
  end
end
