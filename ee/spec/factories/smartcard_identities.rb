# frozen_string_literal: true

FactoryBot.define do
  factory :smartcard_identity do
    subject { 'CN=gitlab-user/emailAddress=gitlab-user@random-corp.org' }

    issuer { 'O=Random Corp Ltd, CN=Random Corp' }

    association :user
  end
end
