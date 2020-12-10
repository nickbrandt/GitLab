# frozen_string_literal: true

class ApplicationExperiment < Gitlab::Experiment
  def publish(_result)
    track(:assignment) # track that we've assigned a variant for this context
    Gon.global.push({ experiment: { name => signature } }, true) # push to client
  end

  def track(action, **event_args)
    return if excluded? # no events for opted out actors or excluded subjects

    Gitlab::Tracking.event(name, action.to_s, **event_args.merge(
      context: (event_args[:context] || []) << SnowplowTracker::SelfDescribingJson.new(
        'iglu:com.gitlab/gitlab_experiment/jsonschema/0-3-0', signature
      )
    ))
  end

  private

  def resolve_variant_name
    variant_names.first if Feature.enabled?(name, self, type: :experiment)
  end
end
