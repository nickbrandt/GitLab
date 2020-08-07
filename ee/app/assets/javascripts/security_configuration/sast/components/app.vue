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
      requirements. Configuration changes made here override those provided by
      GitLab and are excluded from updates. For details of more advanced
      configuration options, see the %{linkStart}GitLab SAST documentation%{linkEnd}.`,
    ),
    loadingErrorText: s__(
      `SecurityConfiguration|Could not retrieve configuration data. Please
      refresh the page, or try again later.`,
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
