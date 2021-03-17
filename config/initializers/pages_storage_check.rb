# frozen_string_literal: true

# This is to make sure at least one storage strategy for Pages is enabled.

return if ::Feature.enabled?(:pages_update_legacy_storage, default_enabled: :yaml)

pages = Settings.pages

return unless pages['enabled']

def check_boolean(val, attribute)
  return if val.nil? || !!val == val

  raise "Please set either true or false for pages:#{attribute}:enabled setting."
end

check_boolean(pages['local_store']['enabled'], 'local_store')
check_boolean(pages['object_store']['enabled'], 'object_store')

if !pages['local_store']['enabled'] && !pages['object_store']['enabled']
  raise "Please enable at least one of the two Pages storage strategy (local_store or object_store) in your config/gitlab.yml - set their 'enabled' attribute to true."
end
