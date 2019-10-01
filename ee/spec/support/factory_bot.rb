# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    FactoryBot.definition_file_paths = [
      Rails.root.join('ee', 'spec', 'factories')
    ]
    FactoryBot.find_definitions

    # Use FactoryBot 4.x behavior:
    # https://github.com/thoughtbot/factory_bot/blob/master/GETTING_STARTED.md#associations
    FactoryBot.use_parent_strategy = false
  end
end
