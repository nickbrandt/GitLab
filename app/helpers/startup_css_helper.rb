# frozen_string_literal: true

# Helper methods for determining startup css filename
#
# Optionally pass a `feature_flag` symbol to check the
# feature flag and append `-<feature_flag>-on` if it is on.
#
# Currently there is only support for a single feature
# flag variant.
#
# See https://gitlab.com/gitlab-org/frontend/gitlab-css-statistics/-/blob/main/lib/gl_startup_extract.js
# for the process which generates the various startup CSS file variants.
module StartupCssHelper
  def startup_css_filename(feature_flag: nil)
    filename = 'startup'

    filename +=
      if current_path?("sessions#new")
        '-signin'
      elsif user_application_theme == 'gl-dark'
        '-dark'
      else
        '-general'
      end

    if feature_flag && Feature.enabled?(feature_flag, current_user)
      filename += "-#{feature_flag.to_s.dasherize}-on"
    end

    filename
  end
end
