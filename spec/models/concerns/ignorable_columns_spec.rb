# frozen_string_literal: true

require 'spec_helper'

describe IgnorableColumns do
  class User < ApplicationRecord
    include IgnorableColumns
  end

  it 'adds columns to ignored_columns' do
    expect do
      User.ignore_columns(:name, :created_at, remove_after: '2019-12-01', remove_with: '12.6')
    end.to change { User.ignored_columns }.from([]).to(%w(name created_at))
  end

  it 'requires remove_after attribute to be set' do
    expect { User.ignore_columns(:name, remove_after: nil, remove_with: 12.6) }.to raise_error
  end

  it 'requires remove_with attribute to be set' do
    expect { User.ignore_columns(:name, remove_after: '2019-12-01', remove_with: nil) }.to raise_error
  end

end