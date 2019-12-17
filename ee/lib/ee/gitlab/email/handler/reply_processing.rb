# frozen_string_literal: true

module EE
  module Gitlab
    module Email
      module Handler
        module ReplyProcessing
          extend ::Gitlab::Utils::Override

          private

          # Support bot is specifically forbidden
          # from using slash commands.
          def strip_quick_actions(content)
            return content unless author.support_bot?

            command_definitions = ::QuickActions::InterpretService.command_definitions
            extractor = ::Gitlab::QuickActions::Extractor.new(command_definitions)

            extractor.extract_commands(content)[0]
          end

          override :process_message
          def process_message(**kwargs)
            strip_quick_actions(super(kwargs))
          end
        end
      end
    end
  end
end
