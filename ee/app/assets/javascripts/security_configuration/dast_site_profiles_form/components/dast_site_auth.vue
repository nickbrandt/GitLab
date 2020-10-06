<script>
import { GlFormGroup, GlFormTextarea, GlFormInput, GlToggle } from '@gitlab/ui';

const isURLTypeMismatch = el => el.type === 'url' && el.validity.typeMismatch;

const validateInputElement = el => {
  const isValid = el.checkValidity();
  const { validationMessage } = el;
  const message = isURLTypeMismatch(el) ? 'UUUPs... :( :( ' : validationMessage;

  return {
    isValid,
    message,
  };
};

const initField = value => ({
  value,
  state: null,
  feedback: null,
});

export default {
  components: {
    GlFormGroup,
    GlFormTextarea,
    GlFormInput,
    GlToggle,
  },
  data() {
    const form = {
      authenticationUrl: initField(),
      userName: initField(),
      password: initField(),
      userNameFormField: initField(),
      passwordFormField: initField(),
      excludedURLs: initField(),
      additionalRequestHeaders: initField(),
    };

    return {
      form,
      // @TODO: change to be "false"
      isAuthEnabled: true,
    };
  },
  computed: {
    isFormValid() {
      return !this.isAuthEnabled || Object.values(this.form).every(({ state }) => state);
    },
  },
  watch: {
    isFormValid: { handler: 'emitUpdate', immediate: true },
  },
  methods: {
    emitUpdate() {
      this.$emit('update', {
        form: this.form,
        isValid: this.isFormValid,
      });
    },
    validate(fieldName, { target }) {
      const { isValid, message } = validateInputElement(target);

      this.form[fieldName].state = isValid;
      this.form[fieldName].feedback = message;
    },
  },
};
</script>

<template>
  <section>
    <gl-form-group :label="s__('DastProfiles|Authentication')">
      <gl-toggle v-model="isAuthEnabled" />
    </gl-form-group>
    <div v-if="isAuthEnabled">
      <div class="row">
        <gl-form-group
          :label="s__('DastProfiles|Authentication URL')"
          :invalid-feedback="form.authenticationUrl.feedback"
          class="col-md-6"
        >
          <gl-form-input
            v-model="form.authenticationUrl.value"
            type="url"
            required
            :state="form.authenticationUrl.state"
            @blur="validate('authenticationUrl', $event)"
          />
        </gl-form-group>
      </div>
      <div class="row">
        <gl-form-group
          :label="s__('DastProfiles|User Name')"
          :invalid-feedback="form.userName.feedback"
          class="col-md-6"
        >
          <gl-form-input
            v-model="form.userName.value"
            type="text"
            required
            :state="form.userName.state"
            @blur="validate('userName', $event)"
          />
        </gl-form-group>
        <gl-form-group
          :label="s__('DastProfiles|Password')"
          :invalid-feedback="form.password.feedback"
          class="col-md-6"
        >
          <gl-form-input
            v-model="form.password.value"
            type="password"
            required
            :state="form.password.state"
            @blur="validate('password', $event)"
          />
        </gl-form-group>
      </div>
      <div class="row">
        <gl-form-group
          :label="s__('DastProfiles|Username form field')"
          :invalid-feedback="form.userNameFormField.feedback"
          class="col-md-6"
        >
          <gl-form-input
            v-model="form.userNameFormField.value"
            type="text"
            required
            :state="form.userNameFormField.state"
            @blur="validate('userNameFormField', $event)"
          />
        </gl-form-group>
        <gl-form-group
          :label="s__('DastProfiles|Password form field')"
          :invalid-feedback="form.passwordFormField.feedback"
          class="col-md-6"
        >
          <gl-form-input
            v-model="form.passwordFormField.value"
            type="password"
            required
            :state="form.passwordFormField.state"
            @blur="validate('passwordFormField', $event)"
          />
        </gl-form-group>
      </div>
      <div class="row">
        <gl-form-group :label="s__('DastProfiles|Excluded URLs (Optional)')" class="col-md-6">
          <gl-form-textarea v-model="form.excludedURLs.value" />
        </gl-form-group>
        <gl-form-group
          :label="s__('DastProfiles|Additional request headers (Optional)')"
          class="col-md-6"
        >
          <gl-form-textarea v-model="form.additionalRequestHeaders.value" />
        </gl-form-group>
      </div>
    </div>
  </section>
</template>
