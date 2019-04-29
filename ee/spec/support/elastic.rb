RSpec.configure do |config|
  config.before(:each, :concerns) do
    Gitlab::Elastic::Helper.create_empty_index
  end

  config.after(:each, :concerns) do
    Gitlab::Elastic::Helper.delete_index
  end
end
