<script>
import { GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { GEO_INFO_URL } from '../constants';
import GeoNodes from './geo_nodes.vue';

export default {
  name: 'GeoNodesBetaApp',
  components: {
    GlSprintf,
    GlLink,
    GlButton,
    GeoNodes,
  },
  computed: {
    ...mapState(['nodes']),
  },
  created() {
    this.fetchNodes();
  },
  methods: {
    ...mapActions(['fetchNodes']),
  },
  GEO_INFO_URL,
};
</script>

<template>
  <section>
    <h3>{{ __('Geo sites') }}</h3>
    <div
      class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-md-align-items-center gl-border-b-1 gl-border-b-solid gl-border-b-gray-100 gl-pb-5"
    >
      <p class="gl-mb-0 gl-mr-5">
        <gl-sprintf
          :message="
            s__(
              'Geo|With GitLab Geo, you can install a special read-only and replicated instance anywhere. %{linkStart}Learn more%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link class="gl-ml-2" :href="$options.GEO_INFO_URL" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <gl-button
        class="gl-ml-auto gl-mr-5 gl-w-full gl-md-w-auto gl-mt-5 gl-md-mt-0"
        variant="confirm"
        href="#"
        target="_blank"
        >{{ __('Add site') }}</gl-button
      >
    </div>
    <geo-nodes v-for="node in nodes" :key="node.id" :node="node" />
  </section>
</template>
