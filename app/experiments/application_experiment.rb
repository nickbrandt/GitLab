# frozen_string_literal: true

class ApplicationExperiment < Gitlab::Experiment # rubocop:disable Gitlab/NamespacedClass
  def enabled?
    return false if Feature::Definition.get(feature_flag_name).nil? # there has to be a feature flag yaml file
    return false unless Gitlab.dev_env_or_com? # we have to be in an environment that allows experiments

    # the feature flag has to be enabled conditionally or fully for the experiment to be enabled
    Feature.get(feature_flag_name).state == :conditional || Feature.get(feature_flag_name).state == :on # rubocop:disable Gitlab/AvoidFeatureGet
  end

  def publish(_result)
    track(:assignment) # track that we've assigned a variant for this context
    Gon.global.push({ experiment: { name => signature } }, true) # push the experiment data to the client
  end

  def track(action, **event_args)
    return unless should_track? # don't track events for excluded contexts

    # track the event, and mix in the experiment signature data
    Gitlab::Tracking.event(name, action.to_s, **event_args.merge(
      context: (event_args[:context] || []) << SnowplowTracker::SelfDescribingJson.new(
        'iglu:com.gitlab/gitlab_experiment/jsonschema/0-3-0', signature
      )
    ))
  end

  def exclude!
    @excluded = true
  end

  def rollout_strategy
    # no-op override in inherited class as desired
  end

  def variants
    # override as desired in inherited class with all variants + control
    # %i[variant1 variant2 control]
    #
    # this will make sure we supply variants as these go together - rollout_strategy of :round_robin must have variants
    raise NotImplementedError, "Inheriting class must supply variants as an array if :round_robin strategy is used" if rollout_strategy == :round_robin
  end

  private

  def feature_flag_name
    name.tr('/', '_')
  end

  def resolve_variant_name
    case rollout_strategy
    when :round_robin
      round_robin_rollout
    else
      percentage_rollout
    end
  end

  def round_robin_rollout
    Strategy::RoundRobin.new(feature_flag_name, variants).execute
  end

  def percentage_rollout
    return variant_names.first if Feature.enabled?(feature_flag_name, self, type: :experiment, default_enabled: :yaml)

    nil # Returning nil vs. :control is important for not caching and rollouts.
  end
end
