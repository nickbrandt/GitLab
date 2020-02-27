# frozen_string_literal: true

require 'securerandom'

module QA
  context 'Enablement - Search' do
    describe 'When using elasticsearch API to search for a known blob', :orchestrated, :elasticsearch, :requires_admin, quarantine: { type: :new } do
      before(:all) do
        @project_name = "api-es-#{SecureRandom.hex(8)}"
        @project_file_content = "elasticsearch: #{SecureRandom.hex(8)}"

        @api_client = Runtime::API::Client.new(:gitlab)
        @unauthorized_user = Resource::User.fabricate_or_use('unauthorized_user', "unauthorized_user_password")
        @unauthorized_api_client = Runtime::API::Client.new(user: @unauthorized_user)

        elasticsearch_state_request = Runtime::API::Request.new(@api_client, '/application/settings')
        response = get elasticsearch_state_request.url

        if response.to_s.match(/"elasticsearch_search":true/) && response.to_s.match(/"elasticsearch_indexing":true/)
          @elasticsearch_original_state_on = true
        end

        if @elasticsearch_original_state_on.nil?
          QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api!
          sleep(60) # wait for the change to propagate before inserting records or else Gitlab::CurrentSettings.elasticsearch_indexing and Elastic::ApplicationVersionedSearch::searchable? will be false
          # this sleep can be removed after we're able to query logs via the API as per this issue https://gitlab.com/gitlab-org/quality/team-tasks/issues/395
        end

        @project = create_project
      end

      after(:all) do
        if !@elasticsearch_original_state_on && !@api_client.nil?
          disable_elasticsearch_request = Runtime::API::Request.new(@api_client, '/application/settings')
          put disable_elasticsearch_request.url, elasticsearch_search: false, elasticsearch_indexing: false
        end
      end

      it 'searches public project and finds a blob as an unauthorized user' do
        sucessful_search(@unauthorized_api_client)
      end

      describe 'When searching a private repository' do
        before(:all) do
          set_project_visibility('private')
        end

        it 'finds a blob as an authorized user' do
          sucessful_search(@api_client)
        end

        it 'does not find a blob as an unauthorized user' do
          QA::Support::Retrier.retry_on_exception(max_attempts: 10, sleep_interval: 3) do
            get create_search_request(@unauthorized_api_client).url
            expect_status(QA::Support::Api::HTTP_STATUS_OK)
            expect(json_body).to be_empty
          end
        end
      end

      private

      def create_project
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = @project_name
          project.api_client = @api_client
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = 'README.md'
          push.file_content = @project_file_content
          push.commit_message = 'Add README.md'
        end

        project
      end

      def create_search_request(api_client)
        Runtime::API::Request.new(api_client, '/search', scope: 'blobs', search: "#{@project_file_content}")
      end

      def sucessful_search(api_client)
        QA::Support::Retrier.retry_on_exception(max_attempts: 10, sleep_interval: 3) do
          get create_search_request(api_client).url
          expect_status(QA::Support::Api::HTTP_STATUS_OK)

          if json_body.empty?
            raise 'Empty search result returned'
          end

          expect(json_body[0][:data]).to match(@project_file_content)
          expect(json_body[0][:project_id]).to equal(@project.id)
        end
      end

      def set_project_visibility(visibility)
        request = Runtime::API::Request.new(@api_client, "/projects/#{@project.id}")
        put request.url, visibility: visibility
        expect_status(QA::Support::Api::HTTP_STATUS_OK)
      end
    end
  end
end
