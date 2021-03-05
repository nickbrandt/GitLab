# frozen_string_literal: true

# TODOs
# - We can move the `variant` override below to a module or common place if we still
#   need this behavior going forward after we are more comfortable with the
#   experiment framework. But, support for this may be added to gitlab-experiment in
#   the future.  See: https://gitlab.com/gitlab-org/gitlab-experiment/-/issues/28
# - Document how to turn this on with this variant opt-in approach, by making sure the
#   feature flag is in the `:conditional` status by running the chatops command
#   to enable the flag for any user (yourself is fine):
#   `/chatops run feature set --user=my-gitlab-username some_feature true`.
#   Or, in dev, just `Feature.enable(:some_feature)`
#   see `ApplicationExperiment#enabled?` for more context.
class CombinedMenuExperiment < ApplicationExperiment # rubocop:disable Gitlab/NamespacedClass
  # Allow clients to set what variant to use via a URL param.
  # Only needs to be passed when it changes, it will be cached.
  #
  # For example:
  #   https://url/path?combined_menu_experiment_variant=candidate
  #   https://url/path?combined_menu_experiment_variant=control
  #
  # Eventually this should not be necessary once gitlab-experiment adds support
  # for controlling via chatops commands. See https://gitlab.com/gitlab-org/gitlab-experiment/-/issues/24
  def variant(value = nil)
    # NOTE: This guard clause is required, because if the feature flag is :off (and thus #enabled? == false),
    #   then we should always return control regardless of what was passed via the override URL param.
    # TODO: This logic is confusing, because variant is not cohesive and overriding it has unexpected
    #   effects, and you have to be concerned about the order of what the superclass is doing internally.
    #   It seems like the extension point should instead be earlier, probably in the middle of
    #   Gitlab::Experiment#initialize, after we have a Context but before we assign @variant_name
    #   and cache it.
    return super unless enabled?

    # See https://gitlab.com/gitlab-org/gitlab-experiment/-/issues/21
    request = context.instance_variable_get(:@request)

    value ||= request.params["#{name}_experiment_variant"]

    # Ensure variant which was passed exists
    value = nil if behaviors[value].blank?

    super(value)
  end
end
