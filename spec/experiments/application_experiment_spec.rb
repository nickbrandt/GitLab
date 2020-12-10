# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationExperiment do
  subject { described_class.new(:stub) }

  describe "publishing results" do
    it "tracks the assignment" do
      expect(subject).to receive(:track).with(:assignment)

      subject.publish(nil)
    end

    it "pushes the experiment knowledge into the client using Gon.global" do
      expect(Gon.global).to receive(:push).with(
        {
          experiment: {
            'stub' => { # string key because it can be namespaced
              experiment: 'stub',
              key: 'e8f65fd8d973f9985dc7ea3cf1614ae1',
              variant: 'control'
            }
          }
        },
        true
      )

      subject.publish(nil)
    end
  end

  describe "tracking events", :snowplow do
    before do
      allow(Gitlab::Tracking).to receive(:event)
    end

    it "doesn't track if excluded" do
      subject.exclude { true }

      subject.track(:action)

      expect_no_snowplow_event
    end

    it "tracks the event with the expected arguments and merged contexts" do
      subject.track(:action, property: '_property_', context: [
        SnowplowTracker::SelfDescribingJson.new('iglu:com.gitlab/fake/jsonschema/0-0-0', { data: '_data_' })
      ])

      expect_snowplow_event(
        category: 'stub',
        action: 'action',
        property: '_property_',
        context: [
          {
            schema: 'iglu:com.gitlab/fake/jsonschema/0-0-0',
            data: { data: '_data_' }
          },
          {
            schema: 'iglu:com.gitlab/gitlab_experiment/jsonschema/0-3-0',
            data: { experiment: 'stub', key: 'e8f65fd8d973f9985dc7ea3cf1614ae1', variant: 'control' }
          }
        ]
      )
    end
  end

  describe "variant resolution" do
    it "returns nil when not rolled out" do
      stub_feature_flags(stub: false)

      expect(subject.variant.name).to eq('control')
    end

    context "when the rollout out to 100%" do
      it "returns the first variant name" do
        subject.try(:variant1) {}
        subject.try(:variant2) {}

        expect(subject.variant.name).to eq('variant1')
      end
    end
  end
end
