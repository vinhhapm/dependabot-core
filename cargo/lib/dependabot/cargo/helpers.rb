# typed: strong
# frozen_string_literal: true

require "yaml"

module Dependabot
  module Cargo
    module Helpers
      extend T::Sig

      sig { params(credentials: T::Array[Dependabot::Credential]).void }
      def self.setup_credentials_in_environment(credentials)
        credentials.each do |cred|
          next if cred["type"] != "cargo_registry"

          # If there is a 'token' property, then apply it.
          # If there is not, it probably means we are running under dependabot-cli which stripped
          # all tokens. So in that case, we assume that the dependabot proxy will re-inject the
          # actual correct token, and we just use 'token' as a placeholder at this point.
          # (We must add these environment variables here, or 'cargo update' will not think it is
          # configured properly for the private registries.)

          token_env_var = "CARGO_REGISTRIES_#{T.must(cred['registry']).upcase.tr('-', '_')}_TOKEN"

          token = "placeholder_token"
          if cred["token"].nil?
            Dependabot.logger.info("No token found for #{cred['registry']}, dependabot-cli proxy will inject it")
          else
            token = cred["token"]
            Dependabot.logger.info(
              "Token found for #{cred['registry']}, setting #{token_env_var} to provided token value"
            )
          end

          ENV[token_env_var] ||= token
        end

        # And set CARGO_REGISTRY_GLOBAL_CREDENTIAL_PROVIDERS here as well, so Cargo will expect tokens
        ENV["CARGO_REGISTRY_GLOBAL_CREDENTIAL_PROVIDERS"] ||= "cargo:token"
      end
    end
  end
end
