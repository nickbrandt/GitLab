<script>
  import {__} from '~/locale';
  import {GlTabs, GlTab, GlPath,    GlFormGroup,
    GlFormTextarea,
    GlButton,} from '@gitlab/ui';
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
      GlFormGroup,
      GlFormTextarea,
      GlButton,
    },
    mixins: [glFeatureFlagsMixin()],
    props: {},

    data() {
      return {
        activeStep: this.$options.items[1].step,
        testAlert: null,
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
        }
        catch (e) {
          console.log('Invalid JSON');
        }
        return Object.keys(flattenObject(parsed));
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

        <div v-if="activeStep === 'finalize'">
          Finalize stage
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
