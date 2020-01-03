# frozen_string_literal: true

require 'spec_helper'

describe API::Namespaces do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let!(:group1) { create(:group, name: 'test.test-group.2') }
  let!(:group2) { create(:group, :nested) }
  let!(:gold_plan) { create(:gold_plan) }

  describe "GET /namespaces" do
    context "when authenticated as admin" do
      it "returns correct attributes" do
        get api("/namespaces", admin)

        group_kind_json_response = json_response.find { |resource| resource['kind'] == 'group' }
        user_kind_json_response = json_response.find { |resource| resource['kind'] == 'user' }

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(group_kind_json_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                                 'parent_id', 'members_count_with_descendants',
                                                                 'plan', 'shared_runners_minutes_limit',
                                                                 'avatar_url', 'web_url', 'trial_ends_on',
                                                                 'extra_shared_runners_minutes_limit', 'billable_members_count')

        expect(user_kind_json_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path',
                                                                'parent_id', 'plan', 'shared_runners_minutes_limit',
                                                                'avatar_url', 'web_url', 'trial_ends_on',
                                                                'extra_shared_runners_minutes_limit', 'billable_members_count')
      end
    end

    context "when authenticated as a regular user" do
      it "returns correct attributes when user can admin group" do
        group1.add_owner(user)

        get api("/namespaces", user)

        owned_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(owned_group_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path', 'trial_ends_on',
                                                             'plan', 'parent_id', 'members_count_with_descendants',
                                                             'avatar_url', 'web_url', 'billable_members_count')
      end

      it "returns correct attributes when user cannot admin group" do
        group1.add_guest(user)

        get api("/namespaces", user)

        guest_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(guest_group_response.keys).to contain_exactly('id', 'kind', 'name', 'path', 'full_path', 'parent_id',
                                                             'avatar_url', 'web_url', 'billable_members_count')
      end
    end

    context "when passing the requested hosted plan" do
      before do
        user1 = create(:user)
        user2 = create(:user)
        group = create(:group)

        group.add_owner(user)
        group.add_developer(user1)
        group.add_guest(user2)
      end

      context 'without a requested plan' do
        it 'counts guest members' do
          get api("/namespaces", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting an invalid plan' do
        it 'counts guest members' do
          get api("/namespaces?requested_hosted_plan=unknown", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting bronze plan' do
        it 'counts guest members' do
          get api("/namespaces?requested_hosted_plan=bronze", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting silver plan' do
        it 'counts guest members' do
          get api("/namespaces?requested_hosted_plan=silver", user)

          expect(json_response.first['billable_members_count']).to eq(3)
        end
      end

      context 'when requesting gold plan' do
        it 'does not count guest members' do
          get api("/namespaces?requested_hosted_plan=gold", user)

          expect(json_response.first['billable_members_count']).to eq(2)
        end
      end
    end
  end

  describe 'PUT /namespaces/:id' do
    before do
      create(:silver_plan)
    end

    context 'when authenticated as admin' do
      it 'updates namespace using full_path when full_path contains dots' do
        put api("/namespaces/#{group1.full_path}", admin), params: { plan: 'silver', shared_runners_minutes_limit: 9001 }

        aggregate_failures do
          expect(response).to have_gitlab_http_status(200)
          expect(json_response['plan']).to eq('silver')
          expect(json_response['shared_runners_minutes_limit']).to eq(9001)
        end
      end

      it 'updates namespace using id' do
        put api("/namespaces/#{group1.id}", admin), params: { plan: 'silver', shared_runners_minutes_limit: 9001 }

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['plan']).to eq('silver')
        expect(json_response['shared_runners_minutes_limit']).to eq(9001)
      end
    end

    context 'when not authenticated as admin' do
      it 'retuns 403' do
        put api("/namespaces/#{group1.id}", user), params: { plan: 'silver' }

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when namespace not found' do
      it 'returns 404' do
        put api("/namespaces/12345", admin), params: { plan: 'silver' }

        expect(response).to have_gitlab_http_status(404)
        expect(json_response).to eq('message' => '404 Namespace Not Found')
      end
    end

    context 'when invalid params' do
      it 'returns validation error' do
        put api("/namespaces/#{group1.id}", admin), params: { plan: 'unknown' }

        expect(response).to have_gitlab_http_status(400)
        expect(json_response['message']).to eq('plan' => ['is not included in the list'])
      end
    end

    [:last_ci_minutes_notification_at, :last_ci_minutes_usage_notification_level].each do |attr|
      context "when namespace has a value for #{attr}" do
        before do
          group1.update_attribute(attr, Time.now)
        end

        it 'resets that value when assigning extra CI minutes' do
          expect do
            put api("/namespaces/#{group1.full_path}", admin), params: { plan: 'silver', extra_shared_runners_minutes_limit: 1000 }
          end.to change { group1.reload.send(attr) }.to(nil)
        end
      end
    end

    context "when customer purchases extra CI minutes" do
      it "ticks instance runners" do
        runners = Ci::Runner.instance_type

        put api("/namespaces/#{group1.full_path}", admin), params: { plan: 'silver', extra_shared_runners_minutes_limit: 1000 }

        expect(runners).to all(receive(:tick_runner_queue))
      end
    end
  end

  describe 'POST :id/gitlab_subscription' do
    let(:params) do
      { seats: 10,
        plan_code: 'gold',
        start_date: '01/01/2018',
        end_date: '01/01/2019' }
    end

    def do_post(current_user, payload)
      post api("/namespaces/#{group1.id}/gitlab_subscription", current_user), params: payload
    end

    context 'when authenticated as a regular user' do
      it 'returns an unauthroized error' do
        do_post(user, params)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as an admin' do
      it 'fails when some attrs are missing' do
        do_post(admin, params.except(:start_date))

        expect(response).to have_gitlab_http_status(400)
      end

      it 'creates a subscription for the Group' do
        do_post(admin, params)

        expect(response).to have_gitlab_http_status(201)
        expect(group1.gitlab_subscription).to be_present
      end

      it 'sets the trial_starts_on to the start_date' do
        do_post(admin, params.merge(trial: true))

        expect(group1.gitlab_subscription.trial_starts_on).to be_present
        expect(group1.gitlab_subscription.trial_starts_on.strftime('%d/%m/%Y')).to eq(params[:start_date])
      end

      it 'creates a subscription using full_path when the namespace path contains dots' do
        post api("/namespaces/#{group1.full_path}/gitlab_subscription", admin), params: params

        aggregate_failures do
          expect(response).to have_gitlab_http_status(201)
          expect(group1.gitlab_subscription).to be_present
        end
      end
    end
  end

  describe 'GET :id/gitlab_subscription' do
    def do_get(current_user)
      get api("/namespaces/#{namespace.id}/gitlab_subscription", current_user)
    end

    set(:silver_plan) { create(:silver_plan) }
    set(:owner) { create(:user) }
    set(:developer) { create(:user) }
    set(:namespace) { create(:group) }
    set(:gitlab_subscription) { create(:gitlab_subscription, hosted_plan: silver_plan, namespace: namespace) }

    before do
      namespace.add_owner(owner)
      namespace.add_developer(developer)
    end

    context 'with a regular user' do
      it 'returns an unauthroized error' do
        do_get(developer)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'with the owner of the Group' do
      it 'has access to the object' do
        do_get(owner)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'is successful using full_path when namespace path contains dots' do
        get api("/namespaces/#{group1.full_path}/gitlab_subscription", admin)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns data in a proper format' do
        do_get(owner)

        expect(json_response.keys).to match_array(%w[plan usage billing])
        expect(json_response['plan'].keys).to match_array(%w[name code trial upgradable])
        expect(json_response['plan']['name']).to eq('Silver')
        expect(json_response['plan']['code']).to eq('silver')
        expect(json_response['plan']['trial']).to eq(false)
        expect(json_response['plan']['upgradable']).to eq(true)
        expect(json_response['usage'].keys).to match_array(%w[seats_in_subscription seats_in_use max_seats_used seats_owed])
        expect(json_response['billing'].keys).to match_array(%w[subscription_start_date subscription_end_date trial_ends_on])
      end
    end
  end

  describe 'PUT :id/gitlab_subscription' do
    def do_put(namespace_id, current_user, payload)
      put api("/namespaces/#{namespace_id}/gitlab_subscription", current_user), params: payload
    end

    set(:namespace) { create(:group, name: 'test.test-group.22') }
    set(:gitlab_subscription) { create(:gitlab_subscription, namespace: namespace) }

    let(:params) do
      {
        seats: 150,
        plan_code: 'silver',
        start_date: '01/01/2018',
        end_date: '01/01/2019'
      }
    end

    context 'when authenticated as a regular user' do
      it 'returns an unauthroized error' do
        do_put(namespace.id, user, { seats: 150 })

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as an admin' do
      context 'when namespace is not found' do
        it 'returns a 404 error', :quarantine do
          do_put(1111, admin, params)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when namespace does not have a subscription' do
        set(:namespace_2) { create(:group) }

        it 'returns a 404 error' do
          do_put(namespace_2.id, admin, params)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when params are invalid' do
        it 'returns a 400 error' do
          do_put(namespace.id, admin, params.merge(seats: nil))

          expect(response).to have_gitlab_http_status(400)
        end
      end

      context 'when params are valid' do
        it 'updates the subscription for the Group' do
          do_put(namespace.id, admin, params)

          expect(response).to have_gitlab_http_status(200)
          expect(gitlab_subscription.reload.seats).to eq(150)
          expect(gitlab_subscription.plan_name).to eq('silver')
          expect(gitlab_subscription.plan_title).to eq('Silver')
        end

        it 'is sucessful using full_path when namespace path contains dots' do
          put api("/namespaces/#{namespace.full_path}/gitlab_subscription", admin), params: params

          expect(response).to have_gitlab_http_status(200)
        end
      end
    end

    context 'setting the trial expiration date' do
      context 'when the attr has a future date' do
        it 'updates the trial expiration date' do
          date = 30.days.from_now.to_date

          do_put(namespace.id, admin, params.merge(trial_ends_on: date))

          expect(response).to have_gitlab_http_status(200)
          expect(gitlab_subscription.reload.trial_ends_on).to eq(date)
        end
      end

      context 'when the attr has an old date' do
        it 'returns 400' do
          do_put(namespace.id, admin, params.merge(trial_ends_on: 2.days.ago.to_date))

          expect(response).to have_gitlab_http_status(400)
          expect(gitlab_subscription.reload.trial_ends_on).to be_nil
        end
      end
    end
  end
end
