# frozen_string_literal: true

require 'digest'

# This is based on https://bitbucket.org/atlassian/atlassian-jwt-ruby
# which is unmaintained and incompatible with later versions of jwt-ruby

module Atlassian
  module Jwt
    class << self
      CANONICAL_QUERY_SEPARATOR = '&'
      ESCAPED_CANONICAL_QUERY_SEPARATOR = '%26'

      def decode(token, secret, validate = true, options = {})
        options = { algorithm: 'HS256' }.merge(options)
        ::JWT.decode(token, secret, validate, options)
      end

      def encode(payload, secret, algorithm = 'HS256', header_fields = {})
        ::JWT.encode(payload, secret, algorithm, header_fields)
      end

      def create_query_string_hash(http_method, uri, base_uri: '')
        Digest::SHA256.hexdigest(
          create_canonical_request(http_method, uri, base_uri)
        )
      end

      def build_claims(issuer:, method:, uri:, base_uri: '', issued_at: nil, expires: nil, other_claims: {})
        issued_at ||= Time.now.to_i
        expires ||= issued_at + 60

        qsh = create_query_string_hash(method, uri, base_uri: base_uri)

        {
          iss: issuer,
          iat: issued_at,
          exp: expires,
          qsh: qsh
        }.merge(other_claims)
      end

      private

      def create_canonical_request(http_method, uri, base_uri)
        uri = URI.parse(uri) unless uri.is_a?(URI)
        base_uri = URI.parse(base_uri) unless base_uri.is_a?(URI)

        [
          http_method.upcase,
          canonicalize_uri(uri, base_uri),
          canonicalize_query_string(uri.query)
        ].join(CANONICAL_QUERY_SEPARATOR)
      end

      def canonicalize_uri(uri, base_uri)
        path = uri.path.sub(/^#{base_uri.path}/, '')
        path = '/' if path.nil? || path.empty?
        path = '/' + path unless path.start_with? '/'
        path.chomp!('/') if path.length > 1
        path.gsub(CANONICAL_QUERY_SEPARATOR, ESCAPED_CANONICAL_QUERY_SEPARATOR)
      end

      def canonicalize_query_string(query)
        return '' if query.nil? || query.empty?

        query = CGI.parse(query)
        query.delete('jwt')

        query.each do |k, v|
          query[k] = v.map { |a| CGI.escape a }.join(',') if v.is_a?(Array)
          query[k].gsub!('+', '%20') # Use %20, not CGI.escape default of "+"
          query[k].gsub!('%7E', '~') # Unescape "~"
        end

        query = Hash[query.sort]
        query.map { |k, v| "#{CGI.escape k}=#{v}" }.join('&')
      end
    end
  end
end
