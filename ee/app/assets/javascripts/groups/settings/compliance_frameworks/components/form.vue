<script>
import { GlAlert, GlForm, GlFormGroup, GlFormInput, GlLoadingIcon } from '@gitlab/ui';

import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/wrapper';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

import getComplianceFrameworkQuery from '../graphql/queries/get_compliance_framework.query.graphql';

const FRAMEWORK_GRAPHQL_ID_TYPE = 'ComplianceManagement::Framework';

export default {
  components: {
    ColorPicker,
    GlAlert,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      complianceFramework: {},
      error: '',
    };
  },
  apollo: {
    complianceFramework: {
      query: getComplianceFrameworkQuery,
      skip() {
        return !this.id;
      },
      variables() {
        return {
          fullPath: this.groupPath,
          complianceFramework: this.id ? convertToGraphQLId(FRAMEWORK_GRAPHQL_ID_TYPE, this.id) : null,
        };
      },
      update(data) {
        const nodes = data.namespace?.complianceFrameworks?.nodes;

        if (nodes.length > 1) {
          throw new Error(this.$options.i18n.multipleResultsIdError);
        }

        return {
          ...nodes[0],
          parsedId: getIdFromGraphQLId(nodes[0].id),
        };
      },
      error(error) {
        this.error = this.$options.i18n.fetchError;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.loading;
    },
    hasLoaded() {
      return !this.isLoading && !this.error;
    },
  },
  i18n: {
    fetchError: s__(
      'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page',
    ),
    multipleResultsIdError: s__(
      'ComplianceFrameworks|The ID given produced more than one result. Please try a different compliance framework',
    ),
    titleInputLabel: s__('ComplianceFrameworks|Title'),
    descriptionInputLabel: s__('ComplianceFrameworks|Description'),
    colorInputLabel: s__('ComplianceFrameworks|Background color'),
  },
};
</script>
<template>
  <div class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100">
    <gl-alert v-if="error" class="gl-mt-5" variant="danger" :dismissible="false">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />

    <gl-form v-if="hasLoaded">
      <gl-form-group :label="$options.i18n.titleInputLabel">
        <gl-form-input :value="complianceFramework.name"/>
      </gl-form-group>

      <gl-form-group :label="$options.i18n.descriptionInputLabel">
        <gl-form-input :value="complianceFramework.description"/>
      </gl-form-group>

      <color-picker :label="$options.i18n.colorInputLabel" :set-color="complianceFramework.color" />
    </gl-form>
  </div>
</template>
