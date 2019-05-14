RSpec.configure do |config|
  config.before(:each, :elastic) do
    stub_ee_application_setting(elasticsearch_experimental_indexer: true)

    Gitlab::Elastic::Helper.create_empty_index
  end

  config.after(:each, :elastic) do
    Gitlab::Elastic::Helper.delete_index
  end
end
