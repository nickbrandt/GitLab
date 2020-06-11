<script>
import GeoSettingsForm from './geo_settings_form.vue';

export default {
  name: 'GeoSettingsApp',
  components: {
    GeoSettingsForm,
  },
};
</script>

<template>
  <article data-testid="geoSettingsContainer">
    <h3 class="page-title">{{ __('Geo Settings') }}</h3>
    <p>
      {{
        __(
          'Set the timeout in seconds to send a secondary node status to the primary and IPs allowed for the secondary nodes.',
        )
      }}
    </p>
    <geo-settings-form />
  </article>
</template>
