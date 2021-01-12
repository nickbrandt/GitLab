<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
} from '@gitlab/ui';

import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/wrapper';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

import getComplianceFrameworkQuery from '../graphql/queries/get_compliance_framework.query.graphql';
import createComplianceFrameworkMutation from '../graphql/queries/create_compliance_framework.mutation.graphql';
import updateComplianceFrameworkMutation from '../graphql/queries/update_compliance_framework.mutation.graphql';

const FRAMEWORK_GRAPHQL_ID_TYPE = 'ComplianceManagement::Framework';

export default {
  components: {
    ColorPicker,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    groupEditPath: {
      type: String,
      required: true,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
    scopedLabelsHelpPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      complianceFramework: {},
      isEditing: Boolean(this.id),
      error: '',
    };
  },
  apollo: {
    complianceFramework: {
      query: getComplianceFrameworkQuery,
      skip() {
        return !this.isEditing;
      },
      variables() {
        return {
          fullPath: this.groupPath,
          complianceFramework: convertToGraphQLId(FRAMEWORK_GRAPHQL_ID_TYPE, this.id),
        };
      },
      update(data) {
        const nodes = data.namespace?.complianceFrameworks?.nodes || [];

        if (!nodes.length) {
          this.setError(
            new Error(this.$options.i18n.unknownFrameworkError),
            this.$options.i18n.fetchError,
          );

          return {};
        }

        return {
          ...nodes[0],
          parsedId: getIdFromGraphQLId(nodes[0].id),
        };
      },
      error(error) {
        this.setError(error, this.$options.i18n.fetchError);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.loading;
    },
    mutation() {
      return this.isEditing ? updateComplianceFrameworkMutation : createComplianceFrameworkMutation;
    },
    mutationVariables() {
      if (this.isEditing) {
        return {
          input: {
            id: this.complianceFramework.id,
            params: {
              name: this.complianceFramework.name,
              description: this.complianceFramework.description,
              color: this.complianceFramework.color,
            },
          },
        };
      }

      return {
        input: {
          namespacePath: this.groupPath,
          params: {
            name: this.complianceFramework.name,
            description: this.complianceFramework.description,
            color: this.complianceFramework.color,
          },
        },
      };
    },
    validTitle() {
      if (Object.keys(this.complianceFramework).includes('name')) {
        return this.complianceFramework.name !== '';
      }

      return true;
    },
  },
  methods: {
    setError(error, userFriendlyText) {
      this.error = userFriendlyText;
      Sentry.captureException(error);
    },
    handleComplianceFrameworkSubmission(errors) {
      if (errors.length) {
        this.setError(new Error(errors[0]), errors[0]);
      } else {
        visitUrl(this.groupEditPath);
      }
    },
    getMutationErrors(data) {
      if (this.isEditing) {
        return data?.updateComplianceFramework?.errors || [];
      }

      return data?.createComplianceFramework?.errors || [];
    },
    async onSubmit(event) {
      event.preventDefault();

      try {
        const { data } = await this.$apollo.mutate({
          mutation: this.mutation,
          variables: this.mutationVariables,
        });

        this.handleComplianceFrameworkSubmission(this.getMutationErrors(data));
      } catch (e) {
        this.setError(e, this.$options.i18n.saveError);
      }
    },
  },
  i18n: {
    unknownFrameworkError: s__(
      'ComplianceFrameworks|Unknown compliance framework given. Please try a different framework or refresh the page',
    ),
    fetchError: s__(
      'ComplianceFrameworks|Error fetching compliance frameworks data. Please refresh the page',
    ),
    saveError: s__(
      'ComplianceFrameworks|Unable to save this compliance framework. Please try again',
    ),
    titleInputLabel: s__('ComplianceFrameworks|Title'),
    titleInputDescription: s__(
      'ComplianceFrameworks|Use %{codeStart}::%{codeEnd} to create a %{linkStart}scoped set%{linkEnd} (eg. %{codeStart}SOX::AWS%{codeEnd})',
    ),
    titleInputInvalid: s__('ComplianceFrameworks|A title is required'),
    descriptionInputLabel: s__('ComplianceFrameworks|Description'),
    colorInputLabel: s__('ComplianceFrameworks|Background color'),
    submitBtnText: s__('ComplianceFrameworks|Save changes'),
    cancelBtnText: s__('ComplianceFrameworks|Cancel'),
  },
};
</script>
<template>
  <div class="gl-border-t-1 gl-border-t-solid gl-border-t-gray-100">
    <gl-alert v-if="error" class="gl-mt-5" variant="danger" :dismissible="false">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />

    <gl-form v-if="!isLoading" @submit="onSubmit">
      <gl-form-group
        :label="$options.i18n.titleInputLabel"
        :invalid-feedback="$options.i18n.titleInputInvalid"
        :state="validTitle"
        data-testid="name-input-group"
      >
        <template #description>
          <gl-sprintf :message="$options.i18n.titleInputDescription">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>

            <template #link="{ content }">
              <gl-link :href="scopedLabelsHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>

        <gl-form-input v-model="complianceFramework.name" data-testid="name-input" />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.descriptionInputLabel">
        <gl-form-input v-model="complianceFramework.description" data-testid="description-input" />
      </gl-form-group>

      <color-picker
        v-model="complianceFramework.color"
        :label="$options.i18n.colorInputLabel"
        :set-color="complianceFramework.color"
      />

      <div
        class="gl-display-flex gl-justify-content-space-between gl-pt-5 gl-border-t-1 gl-border-t-solid gl-border-t-gray-100"
      >
        <gl-button type="submit" variant="success" data-testid="submit-btn">{{
          $options.i18n.submitBtnText
        }}</gl-button>
        <gl-button :href="groupEditPath" data-testid="cancel-btn">{{
          $options.i18n.cancelBtnText
        }}</gl-button>
      </div>
    </gl-form>
  </div>
</template>
