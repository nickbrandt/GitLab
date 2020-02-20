# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200220152540_downcase_pages_domains.rb')

describe DowncasePagesDomains, :migration do
  let(:domains) { table(:pages_domains) }

  it 'removes duplicates and downcases domains' do
    domains.create(id: 1, domain: 'DUplicate.example.com', verification_code: '123')
    domains.create(id: 2, domain: 'duplicate.example.com', verification_code: '124')

    domains.create(id: 3, domain: 'exAMPLE.com', verification_code: '125')

    migrate!

    expect(domains.find_by_id(1)).to be_nil
    expect(domains.find_by_domain('duplicate.example.com').id).to eq(2)
    expect(domains.find(3).domain).to eq('example.com')
  end
end
