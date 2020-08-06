<script>
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import sastCiConfigurationQuery from '../graphql/sast_ci_configuration.query.graphql';
import DynamicFields from './dynamic_fields.vue';
import { extractSastConfigurationEntities } from './utils';

export default {
  components: {
    DynamicFields,
    GlAlert,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  inject: {
    sastDocumentationPath: {
      from: 'sastDocumentationPath',
      default: '',
    },
    projectPath: {
      from: 'projectPath',
      default: '',
    },
  },
  apollo: {
    sastConfigurationEntities: {
      query: sastCiConfigurationQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update: extractSastConfigurationEntities,
      result({ loading }) {
        if (!loading && this.sastConfigurationEntities.length === 0) {
          this.onError();
        }
      },
      error() {
        this.onError();
      },
    },
  },
  data() {
    return {
      sastConfigurationEntities: [],
      hasLoadingError: false,
    };
  },
  methods: {
    onError() {
      this.hasLoadingError = true;
    },
  },
  i18n: {
    helpText: s__(
      `SecurityConfiguration|Customize common SAST settings to suit your
      requirements. More advanced configuration options exist, which you can
      add to the configuration file this tool generates. It's important to note
      that if you make any configurations, they will be saved as overrides and
      will be excluded from automatic updates. We've provided guidance for some
      easily configurable variables below, but our docs go into even more
      depth. %{linkStart}Read more%{linkEnd}`,
    ),
    loadingErrorText: s__(
      `SecurityConfiguration|There was an error loading the configuration.
      Please reload the page to try again.`,
    ),
  },
};
</script>

<template>
  <article>
    <header class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h2 class="h4">
        {{ s__('SecurityConfiguration|SAST Configuration') }}
      </h2>
      <p>
        <gl-sprintf :message="$options.i18n.helpText">
          <template #link="{ content }">
            <gl-link :href="sastDocumentationPath" target="_blank" v-text="content" />
          </template>
        </gl-sprintf>
      </p>
    </header>

    <gl-loading-icon v-if="$apollo.loading" size="lg" />

    <gl-alert v-else-if="hasLoadingError" variant="danger" :dismissible="false">{{
      $options.i18n.loadingErrorText
    }}</gl-alert>

    <dynamic-fields v-else v-model="sastConfigurationEntities" />
  </article>
</template>
