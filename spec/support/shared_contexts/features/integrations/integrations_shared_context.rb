# frozen_string_literal: true

Integration.available_integration_names.each do |service|
  RSpec.shared_context service do
    include JiraServiceHelper if service == 'jira'

    let(:dashed_service) { service.dasherize }
    let(:service_method) { Project.integration_association_name(service) }
    let(:service_klass) { Integration.integration_name_to_model(service) }
    let(:service_instance) { service_klass.new }
    let(:service_fields) { service_instance.fields }
    let(:service_attrs_list) { service_fields.inject([]) {|arr, hash| arr << hash[:name].to_sym } }
    let(:service_attrs) do
      service_attrs_list.inject({}) do |hash, k|
        if k =~ /^(token*|.*_token|.*_key)/
          hash.merge!(k => 'secrettoken')
        elsif service == 'confluence' && k == :confluence_url
          hash.merge!(k => 'https://example.atlassian.net/wiki')
        elsif service == 'datadog' && k == :datadog_site
          hash.merge!(k => 'datadoghq.com')
        elsif k =~ /^(.*_url|url|webhook)/
          hash.merge!(k => "http://example.com")
        elsif service_klass.method_defined?("#{k}?")
          hash.merge!(k => true)
        elsif service == 'irker' && k == :recipients
          hash.merge!(k => 'irc://irc.network.net:666/#channel')
        elsif service == 'irker' && k == :server_port
          hash.merge!(k => 1234)
        elsif service == 'jira' && k == :jira_issue_transition_id
          hash.merge!(k => '1,2,3')
        elsif service == 'emails_on_push' && k == :recipients
          hash.merge!(k => 'foo@bar.com')
        elsif service == 'slack' || service == 'mattermost' && k == :labels_to_be_notified_behavior
          hash.merge!(k => "match_any")
        else
          hash.merge!(k => "someword")
        end
      end
    end

    let(:licensed_features) do
      {
        'github' => :github_project_service_integration
      }
    end

    before do
      enable_license_for_service(service)
      stub_jira_integration_test if service == 'jira'
    end

    def initialize_integration(integration, attrs = {})
      record = project.find_or_initialize_integration(integration)
      record.attributes = attrs
      record.properties = service_attrs
      record.save!
      record
    end

    private

    def enable_license_for_service(service)
      return unless respond_to?(:stub_licensed_features)

      licensed_feature = licensed_features[service]
      return unless licensed_feature

      stub_licensed_features(licensed_feature => true)
      project.clear_memoization(:disabled_integrations)
    end
  end
end

RSpec.shared_context 'integration activation' do
  def click_active_checkbox
    find('label', text: 'Active').click
  end
end
