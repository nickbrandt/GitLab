# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SubscriptionPortal::Client do
  let(:http_response) { nil }
  let(:httparty_response) do
    double(code: http_response.code, response: http_response, body: {}, parsed_response: {})
  end

  let(:http_method) { :post }

  shared_examples 'when response is successful' do
    let(:http_response) { Net::HTTPSuccess.new(1.0, '201', 'OK') }

    it 'has a successful status' do
      allow(Gitlab::HTTP).to receive(http_method).and_return(httparty_response)

      expect(subject[:success]).to eq(true)
    end
  end

  shared_examples 'when response code is 422' do
    let(:http_response) { Net::HTTPUnprocessableEntity.new(1.0, '422', 'Error') }

    it 'has a unprocessable entity status' do
      allow(Gitlab::HTTP).to receive(http_method).and_return(httparty_response)

      expect(subject[:success]).to eq(false)
    end
  end

  shared_examples 'when response code is 500' do
    let(:http_response) { Net::HTTPServerError.new(1.0, '500', 'Error') }

    it 'has a server error status' do
      allow(Gitlab::HTTP).to receive(http_method).and_return(httparty_response)

      expect(subject[:success]).to eq(false)
    end
  end

  describe '#create_trial_account' do
    subject do
      described_class.generate_trial({})
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
  end

  describe '#create_subscription' do
    subject do
      described_class.create_subscription({}, 'customer@mail.com', 'token')
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
  end

  describe '#create_customer' do
    subject do
      described_class.create_customer({})
    end

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
  end

  describe '#payment_form_params' do
    subject do
      described_class.payment_form_params('cc')
    end

    let(:http_method) { :get }

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
  end

  describe '#payment_method' do
    subject do
      described_class.payment_method('1')
    end

    let(:http_method) { :get }

    it_behaves_like 'when response is successful'
    it_behaves_like 'when response code is 422'
    it_behaves_like 'when response code is 500'
  end

  describe '#activate' do
    let(:authentication_token) { 'authentication_token' }

    it 'returns success' do
      expect(described_class).to receive(:http_post).and_return(
        {
          success: true,
          data: {
            "data" => {
              "cloudActivationActivate" => {
                "authenticationToken" => authentication_token,
                "errors" => []
              }
            }
          }
        }
      )

      result = described_class.activate('activation_code_abc')

      expect(result).to eq({ authentication_token: authentication_token, success: true })
    end

    it 'returns failure' do
      expect(described_class).to receive(:http_post).and_return(
        {
          success: true,
          data: {
            "data" => {
              "cloudActivationActivate" => {
                "authenticationToken" => nil,
                "errors" => ["invalid activation code"]
              }
            }
          }
        }
      )

      result = described_class.activate('activation_code_abc')

      expect(result).to eq({ errors: ["invalid activation code"], success: false })
    end
  end

  describe '#plan_upgrade_offer' do
    let(:namespace_id) { 111 }
    let(:headers) do
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Admin-Email" => "gl_com_api@gitlab.com",
        "X-Admin-Token" => "customer_admin_token"
      }
    end

    let(:params) do
      { query: <<~GQL
        {
          subscription(namespaceId: "{:namespace_id=>#{namespace_id}}") {
            eoaStarterBronzeEligible
            assistedUpgradePlanId
            freeUpgradePlanId
          }
        }
      GQL
      }
    end

    subject(:plan_upgrade_offer) { described_class.plan_upgrade_offer(namespace_id: namespace_id) }

    context 'when the response contains errors' do
      before do
        expect(described_class).to receive(:http_post).with('graphql', headers, params).and_return(response)
      end

      let(:response) do
        {
          success: true,
          data: {
            'errors' => [{ 'message' => 'this will be ignored' }]
          }
        }
      end

      it 'returns a failure' do
        expect(plan_upgrade_offer).to eq({ success: false })
      end
    end

    context 'when the response does not contain errors' do
      using RSpec::Parameterized::TableSyntax

      where(:eligible, :assisted_plan_id, :free_plan_id) do
        true | '111111' | '111111'
        true | '111111' | nil
        true | nil      | '111111'
      end

      with_them do
        before do
          allow(described_class).to receive(:http_post).and_return({
              success: true,
              data: { "data" => { "subscription" => {
                "eoaStarterBronzeEligible" => eligible,
                "assistedUpgradePlanId" => assisted_plan_id,
                "freeUpgradePlanId" => free_plan_id
                } } }
          })
        end

        it 'returns the correct response' do
          expect(plan_upgrade_offer).to eq({
            success: true,
            eligible_for_free_upgrade: eligible,
            assisted_upgrade_plan_id: assisted_plan_id,
            free_upgrade_plan_id: free_plan_id
          })
        end
      end

      context 'when subscription is nil' do
        before do
          allow(described_class).to receive(:http_post).and_return({
            success: true,
            data: { "data" => { "subscription" => nil } }
          })
        end

        it 'returns the correct response' do
          expect(plan_upgrade_offer).to eq({
            success: true,
            eligible_for_free_upgrade: nil,
            assisted_upgrade_plan_id: nil,
            free_upgrade_plan_id: nil
          })
        end
      end
    end
  end

  describe '#plan_data' do
    let(:plan_tags) { 'CI_1000_MINUTES_PLAN' }
    let(:headers) do
      {
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "X-Admin-Email" => "gl_com_api@gitlab.com",
        "X-Admin-Token" => "customer_admin_token"
      }
    end

    let(:params) do
      { query: <<~GQL
        {
          plans(planTags: {:plan_tags=>\"#{plan_tags}\"}) {
            id,
            name,
            code,
            active,
            deprecated,
            free,
            pricePerMonth,
            pricePerYear,
            features,
            aboutPageHref,
            hideDeprecatedCard,
          }
        }
      GQL
      }
    end

    subject(:plan_data) { described_class.plan_data(plan_tags: plan_tags) }

    context 'when the response contains errors' do
      before do
        expect(described_class).to receive(:http_post).with('graphql', headers, params).and_return(response)
      end

      let(:response) do
        {
          success: true,
          data: {
            'errors' => [{ 'message' => 'this will be ignored' }]
          }
        }
      end

      it 'returns a failure' do
        expect(plan_data).to eq({ success: false })
      end
    end

    context 'when the response does not contain errors' do
      using RSpec::Parameterized::TableSyntax

      where(:id, :name, :code, :active, :deprecated, :free, :price_per_month, :price_per_year, :features, :about_page_href, :hide_deprecated_card) do
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | false | 1.0 | 12.0 | [] | '/about' | false
        nil | '1000 CI minutes pack' | 'ci_minutes' | true | false | false | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | nil | 'ci_minutes' | true | false | false | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | nil | true | false | false | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | false | false | false | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | true | false | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | true | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | true | 0.83 | 10.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | nil | true | false | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | nil | true | 1.0 | 12.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | nil | 0.83 | 10.0 | [] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | true | 0.83 | 10.0 | ['feature_1'] | '/about' | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | false | 1.0 | 12.0 | [] | nil | false
        'plans_id' | '1000 CI minutes pack' | 'ci_minutes' | true | false | false | 1.0 | 12.0 | [] | '/about' | true
      end

      with_them do
        before do
          allow(described_class).to receive(:http_post).and_return({
              success: true,
              data: { "data" => { "plans" => [{
                "name" => name,
                "code" => code,
                "active" => active,
                "deprecated" => deprecated,
                "free" => free,
                "pricePerMonth" => price_per_month,
                "pricePerYear" => price_per_year,
                "features" => features,
                "aboutPageHref" => about_page_href,
                "hideDeprecatedCard" => hide_deprecated_card
                }] } }
          })
        end

        it 'returns the correct response' do
          expect(plan_data).to eq({
            success: true,
            plans: [{
              name: name,
              code: code,
              active: active == true,
              deprecated: deprecated == true,
              free: free == true,
              price_per_month: price_per_month,
              price_per_year: price_per_year,
              features: features,
              about_page_href: about_page_href,
              hide_deprecated_card: hide_deprecated_card
            }]
          })
        end
      end

      context 'when plans is nil' do
        before do
          allow(described_class).to receive(:http_post).and_return({
            success: true,
            data: { "data" => { "plans" => nil } }
          })
        end

        it 'returns the correct response' do
          expect(plan_data).to eq({
            success: true,
            plans: nil
          })
        end
      end
    end
  end
end
