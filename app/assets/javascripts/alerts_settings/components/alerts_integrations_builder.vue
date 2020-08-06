<script>
  import {__} from '~/locale';
  import {
    GlTabs,
    GlTab,
    GlPath,
    GlFormTextarea,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlNewDropdown,
    GlNewDropdownItem,
  } from '@gitlab/ui';
  import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
  import {flattenObject} from "../helpers";

  import {i18n} from '../constants';

  export default {
    i18n,
    items: [
      {
        title: __('Select Type (Custom)'),
        step: 'select',
      },
      {
        title: __('Configure'),
        step: 'configure',
        selected: true,
      },
      {
        title: __('Finalize'),
        step: 'finalize',
      },
    ],
    components: {
      GlTabs,
      GlTab,
      GlPath,
      GlFormTextarea,
      GlButton,
      GlFormGroup,
      GlFormInput,
      GlNewDropdown,
      GlNewDropdownItem,
    },
    mixins: [glFeatureFlagsMixin()],
    props: {},

    data() {
      return {
        activeStep: this.$options.items[1].step,
        testAlert: null,
        gitlabFields: [
          {
            key: 'title',
            title: __('Title (Text)'),
            mapping: null,
          },
          {
            key: 'startDate',
            title: __('Start time (Date)'),
            mapping: null,
          },
          {
            key: 'severity',
            title: __('Severity (Text)'),
            mapping: null,
          }
        ],
        mappingKeys: null,
      };
    },
    computed: {},
    methods: {
      setActiveStep(path) {
        this.activeStep = path.step;
      },
      parseTestAlert() {
        let parsed;
        try {
          parsed = JSON.parse(this.testAlert);
          this.mappingKeys = Object.keys(flattenObject(parsed));
          this.activeStep = 'finalize'
        } catch (e) {
          console.log('Invalid JSON');
        }
      },
      selectMapping(gitlabFieldKey, mappignKey) {
        const fieldToMap = this.gitlabFields.find(field => field.key === gitlabFieldKey);
        this.$set(fieldToMap, 'mapping', mappignKey)
      },
    },
  };
</script>

<template>
  <div>
    <gl-tabs>
      <gl-tab :title="__('Integrations')">
        <gl-path :items="$options.items" theme="light-blue" @selected="setActiveStep"
                 class="gl-my-4"/>

        <div v-if="activeStep === 'configure'">
          <gl-form-group

            :label="$options.i18n.alertJson"
            label-for="alert-json"
            label-class="label-bold"
          >
            <gl-form-textarea
              v-model.trim="testAlert"
              id="alert-json"
              :placeholder="__('Sample alert payload')"
              rows="10"
              max-rows="30"
            />
          </gl-form-group>
          <gl-button @click="parseTestAlert">{{ $options.i18n.testAlertInfo }}</gl-button>
        </div>

        <div v-if="activeStep === 'finalize'" class="mapping">
          <div class="gl-display-inline-flex gl-justify-content-space-between gl-flex-direction-row">
            <h5>Gitlab alert key</h5>
            <h5>Payload alert key</h5>
            <h5>Define substitute</h5>
          </div>
          <div v-for="gitlabField in gitlabFields"
               class="mapping-row gl-mb-5 gl-display-inline-flex gl-justify-content-space-between gl-flex-direction-row">
            <gl-form-input disabled :value="gitlabField.title" class="gl-display-inline-flex" style="width: 200px;"/>
            <gl-new-dropdown :text="gitlabField.mapping || __('Select mapping')"
                             style="width: 200px;">
              <gl-new-dropdown-item v-for="mappingKey in mappingKeys"
                                    @click="selectMapping(gitlabField.key, mappingKey)">
                {{mappingKey}}
              </gl-new-dropdown-item>
            </gl-new-dropdown>

            <gl-new-dropdown style="width: 200px;">
              <gl-new-dropdown-item v-for="key in mappingKeys">{{key}}</gl-new-dropdown-item>
            </gl-new-dropdown>
          </div>

        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>

<style scoped lang="scss">
  .mapping {
    display: flex;
    flex-direction: column;
  }
</style>
