# frozen_string_literal: true

module ExpandVariables
  VARIABLES_REGEXP = /\$(?<escape>\$)|%(?<escape>%)|\$(?<key>[a-zA-Z_][a-zA-Z0-9_]*)|\${\g<key>?}|%\g<key>%/.freeze
  VARIABLE_REF_CHARS = %w[$ %].freeze

  class << self
    def expand(value, variables)
      replace_with(value, variables, keep_undefined: false)
    end

    def expand_existing(value, variables)
      replace_with(value, variables, keep_undefined: true)
    end

    def possible_var_reference?(value)
      return unless value

      VARIABLE_REF_CHARS.any? { |symbol| value.include?(symbol) }
    end

    private

    def replace_with(value, variables, keep_undefined: true)
      variables_hash = nil

      value.gsub(VARIABLES_REGEXP) do
        variables_hash ||= transform_variables(variables)

        if Regexp.last_match[:key]
          # return variable matched, or return original if undefined
          variables_hash[Regexp.last_match[:key]] || (keep_undefined ? Regexp.last_match[0] : nil)
        else
          # return escaped sequence, the $ or %
          Regexp.last_match[:escape]
        end
      end
    end

    def transform_variables(variables)
      # Lazily initialise variables
      variables = variables.call if variables.is_a?(Proc)

      # Convert Collection to variables
      variables = variables.to_hash if variables.is_a?(Gitlab::Ci::Variables::Collection)

      # Convert hash array to variables
      if variables.is_a?(Array)
        variables = variables.reduce({}) do |hash, variable|
          hash[variable[:key]] = variable[:value]
          hash
        end
      end

      variables
    end
  end
end
