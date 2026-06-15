Rails.application.config.middleware.use OmniAuth::Builder do
  if ENV["SAML_IDP_SSO_URL"].present? && ENV["SAML_IDP_CERT"].present?
    provider :saml,
      idp_sso_service_url:             ENV["SAML_IDP_SSO_URL"],
      idp_cert:                        ENV["SAML_IDP_CERT"],
      sp_entity_id:                    ENV["SAML_SP_ENTITY_ID"],
      assertion_consumer_service_url:  ENV["SAML_ACS_URL"],
      name_identifier_format:          ENV.fetch("SAML_NAME_ID_FORMAT", "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress")
  end
end

OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = [:post]
OmniAuth.config.silence_get_warning = true
