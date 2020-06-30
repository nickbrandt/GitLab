# frozen_string_literal: true

class ConfluenceService < Service
  include ActionView::Helpers::UrlHelper

  prop_accessor :confluence_url

  # validates :confluence_url, presence: true, public_url: true, if: :activated?
  validates :confluence_url, presence: true, public_url: { protocols: %w(https) }, if: :activated?
  validate :validate_confluence_url, if: :activated?

  VALID_HOST_MATCH = /\.atlassian\.net\Z/.freeze
  VALID_PATH_MATCH = /\A\/wiki/.freeze

  FEATURE_FLAG = :confluence_integration

  # Look iunto PublicUrlValidator, AddressableUrlValidator
  # and Gitlab::UrlBlocker.validate!(value, blocker_args)

  def self.feature_enabled?(actor)
    ::Feature.enabled?(FEATURE_FLAG, actor)
  end

  def title
    s_('ConfluenceService|Confluence Wiki')
  end

  def description
    s_('ConfluenceService|Connect a Confluence Cloud Wiki to your GitLab project')
  end

  def detailed_description
    if activated?
      wiki_url = ::Gitlab::Routing.url_helpers.project_wikis_url(project)

      s_(
        'ConfluenceService|Your GitLab Wiki can be accessed here: %{wiki_link}. To re-enable your GitLab Wiki, disable this integration' %
        { wiki_link: link_to(wiki_url, wiki_url) }
      ).html_safe
    else
      s_('ConfluenceService|Enabling the Confluence Wiki will disable the default GitLab Wiki. Your GitLab Wiki data will be saved and you can always re-enable it later by turning off this integration').html_safe
    end
  end

  # def notices

  # end

  def self.to_param
    'confluence'
  end

  def fields
    [
      {
        type: 'text',
        name: 'confluence_url',
        title: 'Confluence Cloud Wiki URL',
        placeholder: s_('ConfluenceService|The URL of the Confluence'),
        required: true
      }
    ]
  end

  def execute(_data)
    response = Gitlab::HTTP.get(properties['confluence_url'], verify: true)
    response.body if response.code == 200
  rescue
    nil
  end

  def self.supported_events
    %w()
  end

  private

  def validate_confluence_url
    return unless properties['confluence_url']

    uri = URI.parse(properties['confluence_url'])

    unless uri.host.match(VALID_HOST_MATCH) && uri.path.match(VALID_PATH_MATCH)
      return errors.add(:base, 'URL must be to a Confluence Cloud Wiki hosted on atlassian.net')
    end
  end
end
