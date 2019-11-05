# frozen_string_literal: true

require 'spec_helper'

describe API::Vulnerabilities do
  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:project) { create(:project, :with_vulnerabilities) }
  let_it_be(:user) { create(:user) }

  shared_examples 'forbids actions on vulnerability in case of disabled features' do
    context 'when "first-class vulnerabilities" feature is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'responds with "not found"' do
        subject

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when security dashboard feature is not available' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'responds with 403 Forbidden' do
        subject

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'GET /projects/:id/vulnerabilities' do
    let(:project_vulnerabilities_path) { "/projects/#{project.id}/vulnerabilities" }

    subject { get api(project_vulnerabilities_path, user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'returns all vulnerabilities of a project' do
        subject

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(response).to match_response_schema('vulnerability_list', dir: 'ee')
        expect(response.headers['X-Total']).to eq project.vulnerabilities.count.to_s
      end

      context 'with pagination' do
        let(:project_vulnerabilities_path) { "#{super()}?page=2&per_page=1" }

        it 'paginates the vulnerabilities according to the pagination params' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(json_response.map { |v| v['id'] }).to contain_exactly(project.vulnerabilities.second.id)
        end
      end

      it_behaves_like 'forbids actions on vulnerability in case of disabled features'
    end

    it_behaves_like 'responds with "not found" when there is no access to the project'
    it_behaves_like 'prevents working with vulnerabilities in case of insufficient privileges'
  end

  describe "POST /vulnerabilities:id/dismiss" do
    before do
      create_list(:vulnerabilities_occurrence, 2, vulnerability: vulnerability, project: vulnerability.project)
    end

    let(:vulnerability) { project.vulnerabilities.first }

    subject { post api("/vulnerabilities/#{vulnerability.id}/dismiss", user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'dismisses a vulnerability and its associated findings' do
        Timecop.freeze do
          subject

          expect(response).to have_gitlab_http_status(201)
          expect(response).to match_response_schema('vulnerability', dir: 'ee')

          expect(vulnerability.reload).to(
            have_attributes(state: 'closed', closed_by: user, closed_at: be_like_time(Time.zone.now)))
          expect(vulnerability.findings).to all have_vulnerability_dismissal_feedback
        end
      end

      context 'when there is a dismissal error' do
        before do
          Grape::Endpoint.before_each do |endpoint|
            allow(endpoint).to receive(:find_vulnerability!).and_wrap_original do |method, *args|
              vulnerability = method.call(*args)

              errors = ActiveModel::Errors.new(vulnerability)
              errors.add(:base, 'something went wrong')

              allow(vulnerability).to receive(:valid?).and_return(false)
              allow(vulnerability).to receive(:errors).and_return(errors)

              vulnerability
            end
          end
        end

        after do
          # resetting according to the https://github.com/ruby-grape/grape#stubbing-helpers
          Grape::Endpoint.before_each nil
        end

        it 'responds with error' do
          subject

          expect(response).to have_gitlab_http_status(400)
          expect(json_response['message']).to eq('base' => ['something went wrong'])
        end
      end

      context 'if a vulnerability is already dismissed' do
        let(:vulnerability) { create(:vulnerability, :closed, project: project) }

        it 'responds with 304 Not Modified' do
          subject

          expect(response).to have_gitlab_http_status(304)
        end
      end

      it_behaves_like 'forbids actions on vulnerability in case of disabled features'
    end

    it_behaves_like 'prevents working with vulnerabilities in case of insufficient privileges'
  end

  describe "POST /vulnerabilities:id/resolve" do
    before do
      create_list(:vulnerabilities_finding, 2, vulnerability: vulnerability)
    end

    let(:vulnerability) { project.vulnerabilities.first }

    subject { post api("/vulnerabilities/#{vulnerability.id}/resolve", user) }

    context 'with an authorized user with proper permissions' do
      before do
        project.add_developer(user)
      end

      it 'resolves a vulnerability and its associated findings' do
        Timecop.freeze do
          subject

          expect(response).to have_gitlab_http_status(201)
          expect(response).to match_response_schema('vulnerability', dir: 'ee')

          expect(vulnerability.reload).to(
            have_attributes(state: 'closed', closed_by: user, closed_at: be_like_time(Time.zone.now)))
          expect(vulnerability.findings).to all have_attributes(state: 'resolved')
        end
      end

      context 'when the vulnerability is already resolved' do
        let(:vulnerability) { create(:vulnerability, :closed, project: project) }

        it 'responds with 304 Not Modified response' do
          subject

          expect(response).to have_gitlab_http_status(304)
        end
      end

      it_behaves_like 'forbids actions on vulnerability in case of disabled features'
    end

    it_behaves_like 'prevents working with vulnerabilities in case of insufficient privileges'
  end
end
