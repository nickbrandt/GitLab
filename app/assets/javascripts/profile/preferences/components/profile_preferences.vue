<script>
import { GlButton, GlFormGroup, GlFormText, GlLink } from '@gitlab/ui';
import createFlash, { FLASH_TYPES } from '~/flash';
import Select2Select from '~/vue_shared/components/select2_select.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { INTEGRATION_VIEW_CONFIGS, i18n } from '../constants';
import { mapChoicesToSelect2Options } from '../utils';
import IntegrationView from './integration_view.vue';

function updateClasses(bodyClasses = '', applicationTheme, layout) {
  // Remove body class for any previous theme, re-add current one
  document.body.classList.remove(...bodyClasses.split(' '));
  document.body.classList.add(applicationTheme);

  // Toggle container-fluid class
  if (layout === 'fluid') {
    document
      .querySelector('.content-wrapper .container-fluid')
      .classList.remove('container-limited');
  } else {
    document.querySelector('.content-wrapper .container-fluid').classList.add('container-limited');
  }
}

export default {
  name: 'ProfilePreferences',
  components: {
    GlFormGroup,
    GlFormText,
    GlLink,
    IntegrationView,
    GlButton,
    Select2Select,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    firstDayOfWeekChoicesWithDefault: 'firstDayOfWeekChoicesWithDefault',
    languageChoices: 'languageChoices',
    profilePreferencesLocalizationHelpPath: 'profilePreferencesLocalizationHelpPath',
    integrationViews: {
      default: [],
    },
    themes: {
      default: [],
    },
    userFields: {
      default: {},
    },
    formEl: 'formEl',
    profilePreferencesPath: 'profilePreferencesPath',
    bodyClasses: 'bodyClasses',
  },
  integrationViewConfigs: INTEGRATION_VIEW_CONFIGS,
  i18n,
  data() {
    let selectedFirstDayOfWeek = null;
    // Do not parse default value (null)
    if (this.userFields.first_day_of_week !== null) {
      selectedFirstDayOfWeek = String(this.userFields.first_day_of_week);
    }

    return {
      isSubmitEnabled: true,
      darkModeOnCreate: null,
      darkModeOnSubmit: null,
      selectedPreferredLanguage: this.userFields.preferred_language,
      selectedFirstDayOfWeek,
      selectedTimeFormatIn24h: this.userFields.time_format_in_24h,
      selectedTimeDisplayRelative: this.userFields.time_display_relative,
    };
  },
  computed: {
    applicationThemes() {
      return this.themes.reduce((themes, theme) => {
        const { id, ...rest } = theme;
        return { ...themes, [id]: rest };
      }, {});
    },
    selectLanguageChoices() {
      return {
        data: mapChoicesToSelect2Options(this.languageChoices),
      };
    },
    selectFirstDayOfWeekChoicesWithDefault() {
      return {
        data: mapChoicesToSelect2Options(this.firstDayOfWeekChoicesWithDefault),
      };
    },
  },
  created() {
    this.formEl.addEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.addEventListener('ajax:success', this.handleSuccess);
    this.formEl.addEventListener('ajax:error', this.handleError);
    this.darkModeOnCreate = this.darkModeSelected();
  },
  beforeDestroy() {
    this.formEl.removeEventListener('ajax:beforeSend', this.handleLoading);
    this.formEl.removeEventListener('ajax:success', this.handleSuccess);
    this.formEl.removeEventListener('ajax:error', this.handleError);
  },
  methods: {
    darkModeSelected() {
      const theme = this.getSelectedTheme();
      return theme ? theme.css_class === 'gl-dark' : null;
    },
    getSelectedTheme() {
      const themeId = new FormData(this.formEl).get('user[theme_id]');
      return this.applicationThemes[themeId] ?? null;
    },
    handleLoading() {
      this.isSubmitEnabled = false;
      this.darkModeOnSubmit = this.darkModeSelected();
    },
    handleSuccess(customEvent) {
      // Reload the page if the theme has changed from light to dark mode or vice versa
      // to correctly load all required styles.
      const modeChanged = this.darkModeOnCreate ? !this.darkModeOnSubmit : this.darkModeOnSubmit;
      if (modeChanged) {
        window.location.reload();
        return;
      }
      updateClasses(this.bodyClasses, this.getSelectedTheme().css_class, this.selectedLayout);
      const { message = this.$options.i18n.defaultSuccess, type = FLASH_TYPES.NOTICE } =
        customEvent?.detail?.[0] || {};
      createFlash({ message, type });
      this.isSubmitEnabled = true;
    },
    handleError(customEvent) {
      const { message = this.$options.i18n.defaultError, type = FLASH_TYPES.ALERT } =
        customEvent?.detail?.[0] || {};
      createFlash({ message, type });
      this.isSubmitEnabled = true;
    },
  },
};
</script>

<template>
  <div class="row gl-mt-3 js-preferences-form">
    <div class="col-sm-12">
      <hr />
    </div>
    <div id="localization" class="col-lg-4 profile-settings-sidebar">
      <h4 class="gl-mt-0">
        {{ $options.i18n.localization }}
      </h4>
      <p>
        {{ $options.i18n.localizationDescription }}
        <gl-link
          class="gl-display-inline-block"
          :href="profilePreferencesLocalizationHelpPath"
          target="_blank"
        >
          {{ $options.i18n.learnMore }} </gl-link
        >.
      </p>
    </div>
    <div class="col-lg-8">
      <gl-form-group
        :label="$options.i18n.language"
        label-for="user_preferred_language"
        data-testid="user-preferred-language-select"
      >
        <select2-select
          id="user_preferred_language"
          v-model="selectedPreferredLanguage"
          name="user[preferred_language]"
          :options="selectLanguageChoices"
        />
        <gl-form-text>
          {{ $options.i18n.experimentalDescription }}
        </gl-form-text>
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.firstDayOfTheWeek"
        label-for="user_first_day_of_week"
        data-testid="user-first-day-of-week-select"
      >
        <select2-select
          id="user_first_day_of_week"
          v-model="selectedFirstDayOfWeek"
          name="user[first_day_of_week]"
          :data-placeholder="selectFirstDayOfWeekChoicesWithDefault.data[0].text"
          :options="selectFirstDayOfWeekChoicesWithDefault"
        />
      </gl-form-group>
    </div>

    <template v-if="glFeatures.userTimeSettings">
      <div class="col-sm-12" data-testid="user-time-settings-rule">
        <hr />
      </div>
      <div class="col-lg-4 profile-settings-sidebar" data-testid="user-time-settings-heading">
        <h4 class="gl-mt-0">
          {{ $options.i18n.timePreferences }}
        </h4>
        <p>
          {{ $options.i18n.timePreferencesDescription }}
        </p>
      </div>
      <div class="col-lg-8">
        <h5>
          {{ $options.i18n.timeFormat }}
        </h5>
        <gl-form-group class="form-check">
          <input name="user[time_format_in_24h]" type="hidden" value="0" />
          <input
            id="user_time_format_in_24h"
            v-model="selectedTimeFormatIn24h"
            data-testid="user-time-format-option"
            class="form-check-input"
            name="user[time_format_in_24h]"
            type="checkbox"
            value="1"
          />
          <label class="form-check-label" for="user_time_format_in_24h">
            {{ $options.i18n.timeFormatLabel }}
          </label>
        </gl-form-group>
        <h5>
          {{ $options.i18n.relativeTime }}
        </h5>
        <gl-form-group class="form-check">
          <input name="user[time_display_relative]" type="hidden" value="0" />
          <input
            id="user_time_display_relative"
            v-model="selectedTimeDisplayRelative"
            data-testid="user-time-relative-option"
            class="form-check-input"
            name="user[time_display_relative]"
            type="checkbox"
            value="1"
          />
          <label class="form-check-label" for="user_time_display_relative">
            {{ $options.i18n.relativeTimeLabel }}
          </label>
          <gl-form-text tag="div">
            {{ $options.i18n.relativeTimeHelpText }}
          </gl-form-text>
        </gl-form-group>
      </div>
    </template>

    <div v-if="integrationViews.length" class="col-sm-12">
      <hr data-testid="profile-preferences-integrations-rule" />
    </div>
    <div v-if="integrationViews.length" class="col-lg-4 profile-settings-sidebar">
      <h4 class="gl-mt-0" data-testid="profile-preferences-integrations-heading">
        {{ $options.i18n.integrations }}
      </h4>
      <p>
        {{ $options.i18n.integrationsDescription }}
      </p>
    </div>
    <div v-if="integrationViews.length" class="col-lg-8">
      <integration-view
        v-for="view in integrationViews"
        :key="view.name"
        :help-link="view.help_link"
        :message="view.message"
        :message-url="view.message_url"
        :config="$options.integrationViewConfigs[view.name]"
      />
    </div>
    <div class="col-lg-4 profile-settings-sidebar"></div>
    <div class="col-lg-8">
      <div class="form-group">
        <gl-button
          variant="success"
          name="commit"
          type="submit"
          :disabled="!isSubmitEnabled"
          :value="$options.i18n.saveChanges"
        >
          {{ $options.i18n.saveChanges }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
