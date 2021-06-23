# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSetting do
  using RSpec::Parameterized::TableSyntax

  subject(:setting) { described_class.create_from_defaults }

  describe 'validations' do
    it { is_expected.to allow_value(100).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(1.1).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_delay) }
    it { is_expected.not_to allow_value((Gitlab::Mirror::MIN_DELAY - 1.minute) / 60).for(:mirror_max_delay) }

    it { is_expected.to allow_value(10).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(nil).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(0).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(1.1).for(:mirror_max_capacity) }
    it { is_expected.not_to allow_value(-1).for(:mirror_max_capacity) }

    it { is_expected.to allow_value(10).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(nil).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(0).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(1.1).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(-1).for(:mirror_capacity_threshold) }
    it { is_expected.not_to allow_value(subject.mirror_max_capacity + 1).for(:mirror_capacity_threshold) }
    it { is_expected.to allow_value(nil).for(:custom_project_templates_group_id) }

    it { is_expected.to allow_value(10).for(:elasticsearch_indexed_file_size_limit_kb) }
    it { is_expected.not_to allow_value(0).for(:elasticsearch_indexed_file_size_limit_kb) }
    it { is_expected.not_to allow_value(nil).for(:elasticsearch_indexed_file_size_limit_kb) }
    it { is_expected.not_to allow_value(1.1).for(:elasticsearch_indexed_file_size_limit_kb) }
    it { is_expected.not_to allow_value(-1).for(:elasticsearch_indexed_file_size_limit_kb) }

    it { is_expected.to allow_value(10).for(:elasticsearch_indexed_field_length_limit) }
    it { is_expected.to allow_value(0).for(:elasticsearch_indexed_field_length_limit) }
    it { is_expected.not_to allow_value(nil).for(:elasticsearch_indexed_field_length_limit) }
    it { is_expected.not_to allow_value(1.1).for(:elasticsearch_indexed_field_length_limit) }
    it { is_expected.not_to allow_value(-1).for(:elasticsearch_indexed_field_length_limit) }

    it { is_expected.to allow_value(25).for(:elasticsearch_max_bulk_size_mb) }
    it { is_expected.not_to allow_value(nil).for(:elasticsearch_max_bulk_size_mb) }
    it { is_expected.not_to allow_value(0).for(:elasticsearch_max_bulk_size_mb) }
    it { is_expected.not_to allow_value(1.1).for(:elasticsearch_max_bulk_size_mb) }
    it { is_expected.not_to allow_value(-1).for(:elasticsearch_max_bulk_size_mb) }

    it { is_expected.to allow_value(2).for(:elasticsearch_max_bulk_concurrency) }
    it { is_expected.not_to allow_value(nil).for(:elasticsearch_max_bulk_concurrency) }
    it { is_expected.not_to allow_value(0).for(:elasticsearch_max_bulk_concurrency) }
    it { is_expected.not_to allow_value(1.1).for(:elasticsearch_max_bulk_concurrency) }
    it { is_expected.not_to allow_value(-1).for(:elasticsearch_max_bulk_concurrency) }

    it { is_expected.to allow_value(30).for(:elasticsearch_client_request_timeout) }
    it { is_expected.to allow_value(0).for(:elasticsearch_client_request_timeout) }
    it { is_expected.not_to allow_value(nil).for(:elasticsearch_client_request_timeout) }
    it { is_expected.not_to allow_value(1.1).for(:elasticsearch_client_request_timeout) }
    it { is_expected.not_to allow_value(-1).for(:elasticsearch_client_request_timeout) }

    it { is_expected.to allow_value('').for(:elasticsearch_username) }
    it { is_expected.to allow_value('a' * 255).for(:elasticsearch_username) }
    it { is_expected.not_to allow_value('a' * 256).for(:elasticsearch_username) }

    it { is_expected.to allow_value(nil).for(:required_instance_ci_template) }
    it { is_expected.not_to allow_value("").for(:required_instance_ci_template) }
    it { is_expected.not_to allow_value("  ").for(:required_instance_ci_template) }
    it { is_expected.to allow_value("template_name").for(:required_instance_ci_template) }

    it { is_expected.to allow_value(1).for(:max_personal_access_token_lifetime) }
    it { is_expected.to allow_value(nil).for(:max_personal_access_token_lifetime) }
    it { is_expected.to allow_value(10).for(:max_personal_access_token_lifetime) }
    it { is_expected.to allow_value(365).for(:max_personal_access_token_lifetime) }
    it { is_expected.not_to allow_value("value").for(:max_personal_access_token_lifetime) }
    it { is_expected.not_to allow_value(2.5).for(:max_personal_access_token_lifetime) }
    it { is_expected.not_to allow_value(-5).for(:max_personal_access_token_lifetime) }
    it { is_expected.not_to allow_value(366).for(:max_personal_access_token_lifetime) }

    it { is_expected.to allow_value(nil).for(:new_user_signups_cap) }
    it { is_expected.to allow_value(1).for(:new_user_signups_cap) }
    it { is_expected.to allow_value(10).for(:new_user_signups_cap) }
    it { is_expected.to allow_value("").for(:new_user_signups_cap) }
    it { is_expected.not_to allow_value("value").for(:new_user_signups_cap) }
    it { is_expected.not_to allow_value(-1).for(:new_user_signups_cap) }
    it { is_expected.not_to allow_value(2.5).for(:new_user_signups_cap) }

    it { is_expected.to allow_value(1).for(:git_two_factor_session_expiry) }
    it { is_expected.to allow_value(10).for(:git_two_factor_session_expiry) }
    it { is_expected.to allow_value(10079).for(:git_two_factor_session_expiry) }
    it { is_expected.to allow_value(10080).for(:git_two_factor_session_expiry) }
    it { is_expected.not_to allow_value(nil).for(:git_two_factor_session_expiry) }
    it { is_expected.not_to allow_value("value").for(:git_two_factor_session_expiry) }
    it { is_expected.not_to allow_value(2.5).for(:git_two_factor_session_expiry) }
    it { is_expected.not_to allow_value(-5).for(:git_two_factor_session_expiry) }
    it { is_expected.not_to allow_value(0).for(:git_two_factor_session_expiry) }
    it { is_expected.not_to allow_value(10081).for(:git_two_factor_session_expiry) }

    describe 'when additional email text is enabled' do
      before do
        stub_licensed_features(email_additional_text: true)
      end

      it { is_expected.to allow_value("a" * subject.email_additional_text_character_limit).for(:email_additional_text) }
      it { is_expected.not_to allow_value("a" * (subject.email_additional_text_character_limit + 1)).for(:email_additional_text) }
    end

    describe 'when secret detection token revocation is enabled' do
      before do
        stub_application_setting(secret_detection_token_revocation_enabled: true)
      end

      it { is_expected.to allow_value("http://test.com").for(:secret_detection_token_revocation_url) }
      it { is_expected.to allow_value("AKVD34#$%56").for(:secret_detection_token_revocation_token) }
      it { is_expected.to allow_value("http://test.com").for(:secret_detection_revocation_token_types_url) }
      it { is_expected.not_to allow_value(nil).for(:secret_detection_token_revocation_url) }
      it { is_expected.not_to allow_value(nil).for(:secret_detection_token_revocation_token) }
      it { is_expected.not_to allow_value(nil).for(:secret_detection_revocation_token_types_url) }
    end

    context 'when validating allowed_ips' do
      where(:allowed_ips, :is_valid) do
        "192.1.1.1"                   | true
        "192.1.1.0/24"                | true
        "192.1.1.0/24, 192.1.20.23"   | true
        "192.1.1.0/24, 192.23.0.0/16" | true
        "192.1.1.0/34"                | false
        "192.1.1.257"                 | false
        "192.1.1.257, 192.1.1.1"      | false
        "300.1.1.0/34"                | false
      end

      with_them do
        specify do
          setting.update_column(:geo_node_allowed_ips, allowed_ips)

          expect(setting.reload.valid?).to eq(is_valid)
        end
      end
    end

    context 'when validating elasticsearch_url' do
      where(:elasticsearch_url, :is_valid) do
        "http://es.localdomain" | true
        "https://es.localdomain" | true
        "http://es.localdomain, https://es.localdomain " | true
        "http://10.0.0.1" | true
        "https://10.0.0.1" | true
        "http://10.0.0.1, https://10.0.0.1" | true
        "http://localhost" | true
        "http://127.0.0.1" | true

        "es.localdomain" | false
        "10.0.0.1" | false
        "http://es.localdomain, es.localdomain" | false
        "http://es.localdomain, 10.0.0.1" | false
        "this_isnt_a_url" | false
      end

      with_them do
        specify do
          setting.elasticsearch_url = elasticsearch_url

          expect(setting.valid?).to eq(is_valid)
        end
      end
    end

    context 'when license presented' do
      let_it_be(:max_active_user_count) { 20 }

      before_all do
        create_current_license({ restrictions: { active_user_count: max_active_user_count } })
      end

      it { is_expected.to allow_value(max_active_user_count - 1).for(:new_user_signups_cap) }
      it { is_expected.to allow_value(max_active_user_count).for(:new_user_signups_cap) }
      it { is_expected.to allow_value(nil).for(:new_user_signups_cap) }
      it { is_expected.not_to allow_value(max_active_user_count + 1).for(:new_user_signups_cap) }
    end
  end

  describe '#should_check_namespace_plan?' do
    before do
      stub_application_setting(check_namespace_plan: check_namespace_plan_column)
      allow(::Gitlab).to receive(:dev_env_org_or_com?) { gl_com }

      # This stub was added in order to force a fallback to Gitlab.dev_env_org_or_com?
      # call testing.
      # Gitlab.dev_env_org_or_com? responds to `false` on test envs
      # and we want to make sure we're still testing
      # should_check_namespace_plan? method through the test-suite (see
      # https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18461#note_69322821).
      allow(Rails).to receive_message_chain(:env, :development?).and_return(false)
      allow(Rails).to receive_message_chain(:env, :test?).and_return(false)
    end

    subject { setting.should_check_namespace_plan? }

    context 'when check_namespace_plan true AND on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { true }

      it 'returns true' do
        is_expected.to eq(true)
      end
    end

    context 'when check_namespace_plan true AND NOT on GitLab.com' do
      let(:check_namespace_plan_column) { true }
      let(:gl_com) { false }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end

    context 'when check_namespace_plan false AND on GitLab.com' do
      let(:check_namespace_plan_column) { false }
      let(:gl_com) { true }

      it 'returns false' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      setting.update_column(:repository_size_limit, 8.exabytes - 1)

      setting.reload

      expect(setting.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe 'elasticsearch licensing' do
    before do
      setting.elasticsearch_search = true
      setting.elasticsearch_indexing = true
    end

    def expect_is_es_licensed
      expect(License).to receive(:feature_available?).with(:elastic_search).at_least(:once)
    end

    it 'disables elasticsearch when unlicensed' do
      expect_is_es_licensed.and_return(false)

      expect(setting.elasticsearch_indexing?).to be_falsy
      expect(setting.elasticsearch_indexing).to be_falsy
      expect(setting.elasticsearch_search?).to be_falsy
      expect(setting.elasticsearch_search).to be_falsy
    end

    it 'enables elasticsearch when licensed' do
      expect_is_es_licensed.and_return(true)

      expect(setting.elasticsearch_indexing?).to be_truthy
      expect(setting.elasticsearch_indexing).to be_truthy
      expect(setting.elasticsearch_search?).to be_truthy
      expect(setting.elasticsearch_search).to be_truthy
    end
  end

  describe '#elasticsearch_pause_indexing' do
    before do
      setting.elasticsearch_pause_indexing = true
    end

    it 'resumes indexing' do
      expect(ElasticIndexingControlWorker).to receive(:perform_async)

      setting.save!
      setting.elasticsearch_pause_indexing = false
      setting.save!
    end
  end

  describe '#elasticsearch_url' do
    it 'presents a single URL as a one-element array' do
      setting.elasticsearch_url = 'http://example.com'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com])
    end

    it 'presents multiple URLs as a many-element array' do
      setting.elasticsearch_url = 'http://example.com,https://invalid.invalid:9200'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://invalid.invalid:9200])
    end

    it 'strips whitespace from around URLs' do
      setting.elasticsearch_url = ' http://example.com, https://invalid.invalid:9200 '

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://invalid.invalid:9200])
    end

    it 'strips trailing slashes from URLs' do
      setting.elasticsearch_url = 'http://example.com/, https://example.com:9200/, https://example.com:9200/prefix//'

      expect(setting.elasticsearch_url).to eq(%w[http://example.com https://example.com:9200 https://example.com:9200/prefix])
    end
  end

  describe '#elasticsearch_url_with_credentials' do
    it 'embeds credentials in the result' do
      setting.elasticsearch_url = 'http://example.com,https://example2.com:9200'
      setting.elasticsearch_username = 'foo'
      setting.elasticsearch_password = 'bar'

      expect(setting.elasticsearch_url_with_credentials).to eq(%w[http://foo:bar@example.com https://foo:bar@example2.com:9200])
    end

    it 'embeds username only' do
      setting.elasticsearch_url = 'http://example.com,https://example2.com:9200'
      setting.elasticsearch_username = 'foo'
      setting.elasticsearch_password = ''

      expect(setting.elasticsearch_url_with_credentials).to eq(%w[http://foo:@example.com https://foo:@example2.com:9200])
    end

    it 'overrides existing embedded credentials' do
      setting.elasticsearch_url = 'http://username:password@example.com,https://test:test@example2.com:9200'
      setting.elasticsearch_username = 'foo'
      setting.elasticsearch_password = 'bar'

      expect(setting.elasticsearch_url_with_credentials).to eq(%w[http://foo:bar@example.com https://foo:bar@example2.com:9200])
    end

    it 'returns original url if credentials blank' do
      setting.elasticsearch_url = 'http://username:password@example.com,https://test:test@example2.com:9200'
      setting.elasticsearch_username = ''
      setting.elasticsearch_password = ''

      expect(setting.elasticsearch_url_with_credentials).to eq(%w[http://username:password@example.com https://test:test@example2.com:9200])
    end
  end

  describe '#elasticsearch_password' do
    it 'does not modify password if it is unchanged in the form' do
      setting.elasticsearch_password = 'foo'

      setting.elasticsearch_password = ApplicationSetting::MASK_PASSWORD

      expect(setting.elasticsearch_password).to eq('foo')
    end
  end

  describe '#elasticsearch_config' do
    it 'places all elasticsearch configuration values into a hash' do
      setting.update!(
        elasticsearch_url: 'http://example.com:9200',
        elasticsearch_username: 'foo',
        elasticsearch_password: 'bar',
        elasticsearch_aws: false,
        elasticsearch_aws_region:     'test-region',
        elasticsearch_aws_access_key: 'test-access-key',
        elasticsearch_aws_secret_access_key: 'test-secret-access-key',
        elasticsearch_max_bulk_size_mb: 67,
        elasticsearch_max_bulk_concurrency: 8,
        elasticsearch_client_request_timeout: 30
      )

      expect(setting.elasticsearch_config).to eq(
        url: ['http://foo:bar@example.com:9200'],
        aws: false,
        aws_region:     'test-region',
        aws_access_key: 'test-access-key',
        aws_secret_access_key: 'test-secret-access-key',
        max_bulk_size_bytes: 67.megabytes,
        max_bulk_concurrency: 8,
        client_request_timeout: 30
      )

      setting.update!(
        elasticsearch_client_request_timeout: 0
      )

      expect(setting.elasticsearch_config).not_to include(:client_request_timeout)
    end

    context 'limiting namespaces and projects' do
      before do
        setting.update!(elasticsearch_indexing: true)
        setting.update!(elasticsearch_limit_indexing: true)
      end

      context 'namespaces' do
        context 'with personal namespaces' do
          let(:namespaces) { create_list(:namespace, 2) }
          let!(:indexed_namespace) { create :elasticsearch_indexed_namespace, namespace: namespaces.last }

          it 'tells you if a namespace is allowed to be indexed' do
            expect(setting.elasticsearch_indexes_namespace?(namespaces.last)).to be_truthy
            expect(setting.elasticsearch_indexes_namespace?(namespaces.first)).to be_falsey
          end
        end

        context 'with groups' do
          let(:groups) { create_list(:group, 2) }
          let!(:indexed_namespace) { create :elasticsearch_indexed_namespace, namespace: groups.last }

          it 'returns groups that are allowed to be indexed' do
            child_group = create(:group, parent: groups.first)
            create :elasticsearch_indexed_namespace, namespace: child_group

            child_group_indexed_through_parent = create(:group, parent: groups.last)

            expect(setting.elasticsearch_limited_namespaces).to match_array(
              [groups.last, child_group, child_group_indexed_through_parent])
            expect(setting.elasticsearch_limited_namespaces(true)).to match_array(
              [groups.last, child_group])
          end
        end

        describe '#elasticsearch_indexes_project?' do
          context 'when project is in a subgroup' do
            let(:root_group) { create(:group) }
            let(:subgroup) { create(:group, parent: root_group) }
            let(:project) { create(:project, group: subgroup) }

            before do
              create(:elasticsearch_indexed_namespace, namespace: root_group)
            end

            it 'allows project to be indexed' do
              expect(setting.elasticsearch_indexes_project?(project)).to be(true)
            end
          end

          context 'when project is in a namespace' do
            let(:namespace) { create(:namespace) }
            let(:project) { create(:project, namespace: namespace) }

            before do
              create(:elasticsearch_indexed_namespace, namespace: namespace)
            end

            it 'allows project to be indexed' do
              expect(setting.elasticsearch_indexes_project?(project)).to be(true)
            end
          end
        end
      end

      context 'projects' do
        let(:projects) { create_list(:project, 2) }
        let!(:indexed_project) { create :elasticsearch_indexed_project, project: projects.last }

        it 'tells you if a project is allowed to be indexed' do
          expect(setting.elasticsearch_indexes_project?(projects.last)).to be(true)
          expect(setting.elasticsearch_indexes_project?(projects.first)).to be(false)
        end

        it 'returns projects that are allowed to be indexed' do
          project_indexed_through_namespace = create(:project)
          create :elasticsearch_indexed_namespace, namespace: project_indexed_through_namespace.namespace

          expect(setting.elasticsearch_limited_projects).to match_array(
            [projects.last, project_indexed_through_namespace])
        end

        it 'uses the ElasticsearchEnabledCache cache' do
          expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:fetch).and_return(true)

          expect(setting.elasticsearch_indexes_project?(projects.first)).to be(true)
        end
      end
    end
  end

  describe '#invalidate_elasticsearch_indexes_cache' do
    it 'deletes the ElasticsearchEnabledCache for projects and namespaces' do
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete).with(:project)
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete).with(:namespace)

      setting.invalidate_elasticsearch_indexes_cache!
    end
  end

  describe '#invalidate_elasticsearch_indexes_cache_for_project!' do
    it 'deletes the ElasticsearchEnabledCache for a single project' do
      project_id = 1
      expect(::Gitlab::Elastic::ElasticsearchEnabledCache).to receive(:delete_record).with(:project, project_id)

      setting.invalidate_elasticsearch_indexes_cache_for_project!(project_id)
    end
  end

  describe '#search_using_elasticsearch?' do
    # Constructs a truth table to run the specs against
    where(indexing: [true, false], searching: [true, false], limiting: [true, false], advanced_global_search_for_limited_indexing: [true, false])

    with_them do
      let_it_be(:included_project_container) { create(:elasticsearch_indexed_project) }
      let_it_be(:included_namespace_container) { create(:elasticsearch_indexed_namespace) }

      let_it_be(:included_project) { included_project_container.project }
      let_it_be(:included_namespace) { included_namespace_container.namespace }

      let_it_be(:excluded_project) { create(:project) }
      let_it_be(:excluded_namespace) { create(:namespace) }

      let(:only_when_enabled_globally) { indexing && searching && !limiting }

      subject { setting.search_using_elasticsearch?(scope: scope) }

      before do
        setting.update!(
          elasticsearch_indexing: indexing,
          elasticsearch_search: searching,
          elasticsearch_limit_indexing: limiting
        )

        stub_feature_flags(advanced_global_search_for_limited_indexing: advanced_global_search_for_limited_indexing)
      end

      context 'global scope' do
        let(:scope) { nil }

        it { is_expected.to eq(indexing && searching && (!limiting || advanced_global_search_for_limited_indexing)) }
      end

      context 'namespace (in scope)' do
        let(:scope) { included_namespace }

        it { is_expected.to eq(indexing && searching) }
      end

      context 'namespace (not in scope)' do
        let(:scope) { excluded_namespace }

        it { is_expected.to eq(only_when_enabled_globally) }
      end

      context 'project (in scope)' do
        let(:scope) { included_project }

        it { is_expected.to eq(indexing && searching) }
      end

      context 'project (not in scope)' do
        let(:scope) { excluded_project }

        it { is_expected.to eq(only_when_enabled_globally) }
      end

      context 'array of projects (all in scope)' do
        let(:scope) { [included_project] }

        it { is_expected.to eq(indexing && searching) }
      end

      context 'array of projects (all not in scope)' do
        let(:scope) { [excluded_project] }

        it { is_expected.to eq(only_when_enabled_globally) }
      end

      context 'array of projects (some in scope)' do
        let(:scope) { [included_project, excluded_project] }

        it { is_expected.to eq(indexing && searching) }
      end
    end
  end

  describe 'custom project templates' do
    let(:group) { create(:group) }
    let(:projects) { create_list(:project, 3, namespace: group) }

    before do
      setting.update_column(:custom_project_templates_group_id, group.id)

      setting.reload
    end

    context 'when custom_project_templates feature is enabled' do
      before do
        stub_licensed_features(custom_project_templates: true)
      end

      describe '#custom_project_templates_enabled?' do
        it 'returns true' do
          expect(setting.custom_project_templates_enabled?).to be_truthy
        end
      end

      describe '#custom_project_template_id' do
        it 'returns group id' do
          expect(setting.custom_project_templates_group_id).to eq group.id
        end
      end

      describe '#available_custom_project_templates' do
        it 'returns group projects' do
          expect(setting.available_custom_project_templates).to match_array(projects)
        end

        it 'returns an empty array if group is not set' do
          allow(setting).to receive(:custom_project_template_id).and_return(nil)

          expect(setting.available_custom_project_templates).to eq []
        end
      end
    end

    context 'when custom_project_templates feature is disabled' do
      before do
        stub_licensed_features(custom_project_templates: false)
      end

      describe '#custom_project_templates_enabled?' do
        it 'returns false' do
          expect(setting.custom_project_templates_enabled?).to be false
        end
      end

      describe '#custom_project_template_id' do
        it 'returns false' do
          expect(setting.custom_project_templates_group_id).to be false
        end
      end

      describe '#available_custom_project_templates' do
        it 'returns an empty relation' do
          expect(setting.available_custom_project_templates).to be_empty
        end
      end
    end
  end

  describe '#instance_review_permitted?' do
    subject { setting.instance_review_permitted? }

    context 'for instances with a valid license' do
      before do
        license = create(:license, plan: ::License::PREMIUM_PLAN)
        allow(License).to receive(:current).and_return(license)
      end

      it 'is not permitted' do
        expect(subject).to be_falsey
      end
    end

    context 'for instances without a valid license' do
      before do
        allow(License).to receive(:current).and_return(nil)
        expect(Rails.cache).to receive(:fetch).and_return(
          ::ApplicationSetting::INSTANCE_REVIEW_MIN_USERS + users_over_minimum
        )
      end

      where(users_over_minimum: [-1, 0, 1])

      with_them do
        it { is_expected.to be(users_over_minimum >= 0) }
      end
    end
  end

  describe '#max_personal_access_token_lifetime_from_now' do
    subject { setting.max_personal_access_token_lifetime_from_now }

    let(:days_from_now) { nil }

    before do
      stub_application_setting(max_personal_access_token_lifetime: days_from_now)
    end

    context 'when max_personal_access_token_lifetime is defined' do
      let(:days_from_now) { 30 }

      it 'is a date time' do
        expect(subject).to be_a Time
      end

      it 'is in the future' do
        expect(subject).to be > Time.zone.now
      end

      it 'is in days_from_now' do
        expect((subject.to_date - Date.current).to_i).to eq days_from_now
      end
    end

    context 'when max_personal_access_token_lifetime is nil' do
      it 'is nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe 'updates to max_personal_access_token_lifetime' do
    context 'without personal_access_token_expiration_policy licensed' do
      before do
        stub_licensed_features(personal_access_token_expiration_policy: false)
      end

      it "doesn't call the update lifetime service" do
        expect(::PersonalAccessTokens::Instance::UpdateLifetimeService).not_to receive(:new)

        setting.save
      end
    end

    context 'with personal_access_token_expiration_policy licensed' do
      before do
        setting.max_personal_access_token_lifetime = 30
        stub_licensed_features(personal_access_token_expiration_policy: true)
      end

      it 'executes the update lifetime service' do
        expect_next_instance_of(::PersonalAccessTokens::Instance::UpdateLifetimeService) do |service|
          expect(service).to receive(:execute)
        end

        setting.save
      end
    end
  end

  describe '#compliance_frameworks' do
    it 'sorts the list' do
      setting.compliance_frameworks = [5, 4, 1, 3, 2]

      expect(setting.compliance_frameworks).to eq([1, 2, 3, 4, 5])
    end

    it 'removes duplicates' do
      setting.compliance_frameworks = [1, 2, 2, 3, 3, 3]

      expect(setting.compliance_frameworks).to eq([1, 2, 3])
    end

    it 'sets empty values' do
      setting.compliance_frameworks = [""]

      expect(setting.compliance_frameworks).to eq([])
    end
  end

  describe '#should_apply_user_signup_cap?' do
    subject { setting.should_apply_user_signup_cap? }

    before do
      allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(new_user_signups_cap)
    end

    context 'when new_user_signups_cap setting is nil' do
      let(:new_user_signups_cap) { nil }

      it { is_expected.to be false }
    end

    context 'when new_user_signups_cap setting is set to any number' do
      let(:new_user_signups_cap) { 10 }

      it { is_expected.to be true }
    end
  end

  describe 'maintenance mode setting' do
    it 'defaults to false' do
      expect(subject.maintenance_mode).to be false
    end
  end
end
