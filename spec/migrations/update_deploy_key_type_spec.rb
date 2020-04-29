# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'post_migrate', '20200422204504_update_deploy_key_type.rb')

describe UpdateDeployKeyType, :migration do
  let(:keys) { table(:keys) }
  let(:key1) {'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQChrnUAEU93fwxXa6taxVu5xueEcJ1tx7y2o55kJLdYdICpZbjB9RX84LGHmrWSpblhg6SA61XS7BVb/iuJ1NJQXW+uVS4aKrdv8iJs1G0dM51jlu+rirhWfR6vFe935mSW6PeXWkKPqPytXQmUutO0ofYObIsIhjwYQVp7gZnFFqNHFszHSI8WBcg2wwezALc2yEfRdM082kfFwEkLNjtbOFgg87Pr9pka2PGU80UOO+rC7N04waXUMWLXWX5AIHCNGxa9DZuTadYLAXrqYZNzhqtzYejMawtO4UIcXmHcXqWXHMSteTq1dOk3mJ7FEVZHoo5MgtRFUhlgFYPDbBfuxT0GaLtujGUEzncNCTnw1C/yaEhjn4lguuspBFW/2ZW9xSasmWCcAcNAbWNlR2VAFCFKcL3caN0acxccOtdaXbnkSKJrbLHeYB1LMIY1o+eGH/spksjVJ1n+Z4H6afVF6KAA76Ao8jl2nD40zsFOI9iY0Uf5z25pkwoJXfeCELigQVsF0rsG37QD/pj2+ui1XQSpufQJgkeQ5d0Ld3XwioVX7/zMVUGT1UKMBA5tLH9oAWiDPNxT7Z85QdlP1vP6wih8X0uJetKcPyeKk6hlfJNx+mg/djdgRgh/W8Jyw6NLZuxvNcvsygi0rIiMZUp8kqK/0rg8/dFiRU8F06N+7w== email@example.com'}
  let(:key2) { key1.gsub('AAAA', 'BBBB') }
  let(:key3) { key1.gsub('AAAA', 'CCCC') }
  let(:project_deploy_key_type) { DeployKey.deploy_key_types[:project_type] }

  before do
    keys.create!(title: 'deploy key 1', type: 'DeployKey', key: key1)
    keys.create!(title: 'regular key 1', type: nil, key: key2)
    keys.create!(title: 'deploy key 2', type: 'DeployKey', key: key3)
  end

  it 'updates the column accordingly' do
    migrate!

    keys.where(type: 'DeployKey').each do |deploy_key|
      expect(deploy_key.deploy_key_type).to eq(project_deploy_key_type)
    end
    expect(keys.find_by(type: nil).deploy_key_type).to be_nil
  end
end
