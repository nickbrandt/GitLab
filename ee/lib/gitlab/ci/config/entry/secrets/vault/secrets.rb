# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Secrets
          class Vault
            ##
            # Entry that represents collection of Vault secrets.
            #
            class Secrets < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Configurable

              def compose!(deps = nil)
                super do
                  @config.each do |name, config|
                    factory = ::Gitlab::Config::Entry::Factory.new(Entry::Secrets::Vault::Secret)
                      .value(config || {})
                      .metadata(name: name)
                      .with(key: name, parent: self, description: "#{name} Vault secret definition") # rubocop:disable CodeReuse/ActiveRecord

                    @entries[name] = factory.create!
                  end

                  @entries.each_value do |entry|
                    entry.compose!(deps)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
