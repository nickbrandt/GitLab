# frozen_string_literal: true

module Gitlab
  module WikiPages
    class FrontMatterParser
      # A ParseResult contains the de-serialized front-matter, the stripped
      # content, and maybe an error, explaining why there is no front-matter.
      ParseResult = Struct.new(:front_matter, :content, :reason, :error, keyword_init: true)

      class NoFrontMatter < StandardError
        attr_reader :reason

        def initialize(reason)
          super
          @reason = reason
        end
      end

      FEATURE_FLAG = :wiki_front_matter

      # We limit the maximum length of text we are prepared to parse as YAML, to
      # avoid exploitations and attempts to consume memory and CPU. We allow for:
      #  - a title line
      #  - a "slugs:" line
      #  - and up to 50 slugs
      #
      # This limit does not take comments into account.
      MAX_SLUGS = 50
      SLUG_LINE_LENGTH = (4 + Gitlab::WikiPages::MAX_DIRECTORY_BYTES + 1 + Gitlab::WikiPages::MAX_TITLE_BYTES)
      MAX_FRONT_MATTER_LENGTH = (8 + Gitlab::WikiPages::MAX_TITLE_BYTES) + 7 + (SLUG_LINE_LENGTH * MAX_SLUGS)

      # @param [String] wiki_content
      # @param [FeatureGate] feature_gate The scope for feature availability
      #                                    (usually a project)
      def initialize(wiki_content, feature_gate)
        @wiki_content = wiki_content
        @feature_gate = feature_gate
      end

      def self.enabled?(gate = nil)
        Feature.enabled?(FEATURE_FLAG, gate)
      end

      def parse
        ParseResult.new(front_matter: extract_front_matter, content: strip_front_matter)
      rescue NoFrontMatter => e
        ParseResult.new(front_matter: {}, content: wiki_content, reason: e.reason, error: e.cause)
      end

      private

      attr_reader :wiki_content, :feature_gate

      def extract_front_matter
        ensure_enabled!
        front_matter, lang = extract
        front_matter = parse_string(front_matter, lang)
        validate(front_matter)

        front_matter
      end

      def parse_string(source, lang)
        raise NoFrontMatter, :not_yaml unless lang == 'yaml'

        YAML.safe_load(source, symbolize_names: true)
      rescue Psych::DisallowedClass, Psych::SyntaxError
        raise NoFrontMatter, :parse_error
      end

      def validate(parsed)
        raise NoFrontMatter, :not_mapping unless Hash === parsed
      end

      def extract
        raise NoFrontMatter, :no_content unless wiki_content.present?

        match = Gitlab::FrontMatter::PATTERN.match(wiki_content) if wiki_content.present?
        raise NoFrontMatter, :no_pattern_match unless match
        raise NoFrontMatter, :too_long if match[:front_matter].size > MAX_FRONT_MATTER_LENGTH

        lang = match[:lang].downcase.presence || Gitlab::FrontMatter::DELIM_LANG[match[:delim]]
        [match[:front_matter], lang]
      end

      def ensure_enabled!
        raise NoFrontMatter, :feature_flag_disabled unless self.class.enabled?(feature_gate)
      end

      def strip_front_matter
        wiki_content.gsub(Gitlab::FrontMatter::PATTERN, '')
      end
    end
  end
end
