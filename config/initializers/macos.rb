# frozen_string_literal: true

if /darwin/ =~ RUBY_PLATFORM
  Gitlab::Cluster::LifecycleEvents.on_master_start do
    require 'fiddle'

    # Dynamically load Foundation.framework, ~implicitly~ initialising
    # the Objective-C runtime before any forking happens in Unicorn
    #
    # From https://bugs.ruby-lang.org/issues/14009
    Fiddle.dlopen '/System/Library/Frameworks/Foundation.framework/Foundation'
  end
end
