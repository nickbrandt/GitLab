# frozen_string_literal: true

require 'spec_helper'

describe EE::API::Entities::Nuget::PackageMetadataCatalogEntry do
  let(:entry) do
    {
      json_url: 'http://sandbox.com/json/package',
      authors: 'Authors',
      dependencies: [],
      package_name: 'PackageTest',
      package_version: '1.2.3',
      tags: 'tag1 tag2 tag3',
      archive_url: 'http://sandbox.com/archive/package',
      summary: 'Summary'
    }
  end

  let(:expected) do
    {
      '@id': 'http://sandbox.com/json/package',
      'id': 'PackageTest',
      'version': '1.2.3',
      'authors': 'Authors',
      'dependencyGroups': [],
      'tags': 'tag1 tag2 tag3',
      'packageContent': 'http://sandbox.com/archive/package',
      'summary': 'Summary'
    }
  end

  subject { described_class.new(entry).as_json }

  it { is_expected.to eq(expected) }
end
