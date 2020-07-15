<script>
import * as Sentry from '@sentry/browser';
import { __, s__ } from '~/locale';
import { isAbsolute, redirectTo } from '~/lib/utils/url_utility';
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput, GlModal } from '@gitlab/ui';
import dastSiteProfileCreateMutation from '../graphql/dast_site_profile_create.mutation.graphql';

const initField = value => ({
  value,
  state: null,
  feedback: null,
});

export default {
  name: 'DastSiteProfileForm',
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlModal,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    profilesLibraryPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      form: {
        profileName: initField(''),
        targetUrl: initField(''),
      },
      loading: false,
      showAlert: false,
    };
  },
  computed: {
    formData() {
      return {
        fullPath: this.fullPath,
        ...Object.fromEntries(Object.entries(this.form).map(([key, { value }]) => [key, value])),
      };
    },
    formHasErrors() {
      return Object.values(this.form).some(({ state }) => state === false);
    },
    someFieldEmpty() {
      return Object.values(this.form).some(({ value }) => !value);
    },
    everyFieldEmpty() {
      return Object.values(this.form).every(({ value }) => !value);
    },
    isSubmitDisabled() {
      return this.formHasErrors || this.someFieldEmpty;
    },
  },
  methods: {
    validateTargetUrl() {
      if (!isAbsolute(this.form.targetUrl.value)) {
        this.form.targetUrl.state = false;
        this.form.targetUrl.feedback = s__(
          'DastProfiles|Please enter a valid URL format, ex: http://www.example.com/home',
        );
        return;
      }
      this.form.targetUrl.state = true;
      this.form.targetUrl.feedback = null;
    },
    onSubmit() {
      this.loading = true;
      this.showAlert = false;
      this.$apollo
        .mutate({
          mutation: dastSiteProfileCreateMutation,
          variables: this.formData,
        })
        .then(data => {
          if (data.errors?.length > 0) {
            throw new Error(data.errors);
          }
          redirectTo(this.profilesLibraryPath);
        })
        .catch(e => {
          Sentry.captureException(e);
          this.showAlert = true;
          this.loading = false;
        });
    },
    onCancelClicked() {
      if (this.everyFieldEmpty) {
        this.discard();
      } else {
        this.$refs[this.$options.modalId].show();
      }
    },
    discard() {
      redirectTo(this.profilesLibraryPath);
    },
  },
  modalId: 'deleteDastProfileModal',
  i18n: {
    modalTitle: s__('DastProfiles|Do you want to discard this site profile?'),
    modalOkTitle: __('Discard'),
    modalCancelTitle: __('Cancel'),
  },
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-alert v-if="showAlert" variant="danger" @dismiss="showAlert = false">
      {{ s__('DastProfiles|Could not create the site profile. Please try again.') }}
    </gl-alert>
    <h2 class="gl-mb-6">
      {{ s__('DastProfiles|New site profile') }}
    </h2>

    <gl-form-group :label="s__('DastProfiles|Profile name')">
      <gl-form-input
        v-model="form.profileName.value"
        class="mw-460"
        data-testid="profile-name-input"
        type="text"
      />
    </gl-form-group>

    <hr />

    <gl-form-group
      :invalid-feedback="form.targetUrl.feedback"
      :label="s__('DastProfiles|Target URL')"
    >
      <gl-form-input
        v-model="form.targetUrl.value"
        class="mw-460"
        data-testid="target-url-input"
        type="url"
        :state="form.targetUrl.state"
        @input="validateTargetUrl"
      />
    </gl-form-group>

    <hr />

    <div class="gl-mt-6 gl-pt-6">
      <gl-button
        type="submit"
        variant="success"
        class="js-no-auto-disable"
        data-testid="dast-site-profile-form-submit-button"
        :disabled="isSubmitDisabled"
        :loading="loading"
      >
        {{ s__('DastProfiles|Save profile') }}
      </gl-button>
      <gl-button data-testid="dast-site-profile-form-cancel-button" @click="onCancelClicked">
        {{ __('Cancel') }}
      </gl-button>
    </div>

    <gl-modal
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      :title="$options.i18n.modalTitle"
      :ok-title="$options.i18n.modalOkTitle"
      :cancel-title="$options.i18n.modalCancelTitle"
      ok-variant="danger"
      body-class="gl-display-none"
      data-testid="dast-site-profile-form-cancel-modal"
      @ok="discard()"
    />
  </gl-form>
</template>
