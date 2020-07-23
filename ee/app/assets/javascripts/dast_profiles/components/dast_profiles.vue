<script>
import { GlButton, GlTab, GlTabs } from '@gitlab/ui';
import ProfilesListing from './dast_profiles_listing.vue';

export default {
  components: {
    GlButton,
    GlTab,
    GlTabs,
    ProfilesListing,
  },
  props: {
    newDastSiteProfilePath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <section>
    <header>
      <div class="gl-display-flex gl-align-items-center gl-pt-6 gl-pb-4">
        <h2 class="my-0">
          {{ s__('DastProfiles|Manage Profiles') }}
        </h2>
        <gl-button
          :href="newDastSiteProfilePath"
          category="primary"
          variant="success"
          class="gl-ml-auto"
        >
          {{ s__('DastProfiles|New Site Profile') }}
        </gl-button>
      </div>
      <p>
        {{
          s__(
            'DastProfiles|Save commonly used configurations for target sites and scan specifications as profiles. Use these with an on-demand scan.',
          )
        }}
      </p>
    </header>
    <gl-tabs>
      <gl-tab>
        <template #title>
          <span>{{ s__('DastProfiles|Site Profiles') }}</span>
        </template>

        <profiles-listing />
      </gl-tab>
    </gl-tabs>
  </section>
</template>
