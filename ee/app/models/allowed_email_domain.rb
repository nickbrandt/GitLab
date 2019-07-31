# frozen_string_literal: true

class AllowedEmailDomain < ApplicationRecord
  RESERVED_DOMAINS = [
    '*@gmail.com',
    '*@yahoo.com',
    '*@hotmail.com',
    '*@aol.com',
    '*@msn.com',
    '*@hotmail.co.uk',
   	'*@hotmail.fr'
  ].freeze

  validates :domain, exclusion: { in: RESERVED_DOMAINS,
    message: _('The domain you entered is not allowed.') }

  validates :domain, format: { with: /\*\@\w*\.*./,
    message: _('The domain you entered is not allowed.') }

  belongs_to :group, class_name: 'Group', foreign_key: :namespace_id
end
