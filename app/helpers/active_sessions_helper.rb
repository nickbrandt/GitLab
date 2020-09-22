# frozen_string_literal: true

module ActiveSessionsHelper
  # Maps a device type as defined in `ActiveSession` to an svg icon name and
  # outputs the icon html.
  #
  # see `DeviceDetector::Device::DEVICE_NAMES` about the available device types
  def active_session_device_type_icon(active_session)
    icon_name =
      case active_session.device_type
      when 'smartphone', 'feature phone', 'phablet'
        'mobile'
      when 'tablet'
        'tablet'
      when 'tv', 'smart display', 'camera', 'portable media player', 'console'
        'media'
      when 'car browser'
        'car'
      else
        'monitor-o'
      end

    sprite_icon(icon_name, css_class: 'gl-mt-2')
  end

  def session_namespaces
    namespace_ids = ActiveSession.with_namespace_ids(current_user).map { |s| s['namespace_id'] }
    Namespace.where(id: namespace_ids)
  end
end
