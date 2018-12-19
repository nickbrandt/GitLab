# frozen_string_literal: true

module EE
  module SelectsHelper
    def ldap_server_select_options
      options_from_collection_for_select(
        ::Gitlab::Auth::LDAP::Config.available_servers,
        'provider_name',
        'label'
      )
    end

    def admin_email_select_tag(id, opts = {})
      css_class = ["ajax-admin-email-select"]
      css_class << "multiselect" if opts[:multiple]
      css_class << opts[:class] if opts[:class]
      value = opts[:selected] || ''

      hidden_field_tag(id, value, class: css_class.join(' '))
    end
  end
end
