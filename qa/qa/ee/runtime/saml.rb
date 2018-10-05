# frozen_string_literal: true
module QA
  module EE
    module Runtime
      module Saml
        def self.idp_sso_url
          "https://#{QA::Runtime::Env.simple_saml_hostname || 'localhost'}:8443/simplesaml/saml2/idp/SSOService.php"
        end

        def self.idp_certificate_fingerprint
          '119b9e027959cdb7c662cfd075d9e2ef384e445f'
        end
      end
    end
  end
end
