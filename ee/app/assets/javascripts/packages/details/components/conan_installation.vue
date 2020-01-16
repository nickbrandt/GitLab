<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import CodeInstruction from './code_instruction.vue';
import Tracking from '~/tracking';
import { TrackingActions, TrackingLabels } from '../constants';
import { generateConanRecipe, trackInstallationTabChange } from '../utils';

export default {
  name: 'ConanInstallation',
  components: {
    CodeInstruction,
    GlTab,
    GlTabs,
  },
  mixins: [
    Tracking.mixin({
      label: TrackingLabels.CONAN_INSTALLATION,
    }),
    trackInstallationTabChange,
  ],
  props: {
    heading: {
      type: String,
      default: s__('PackageRegistry|Package installation'),
      required: false,
    },
    packageEntity: {
      type: Object,
      required: true,
    },
    registryUrl: {
      type: String,
      required: true,
    },
    helpUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    conanCommand() {
      const recipe = generateConanRecipe(this.packageEntity);

      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `conan install ${recipe} --remote=gitlab`;
    },
    setupCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `conan remote add gitlab ${this.registryUrl}`;
    },
    helpText() {
      return sprintf(
        s__(
          `PackageRegistry|For more information on the Conan registry, %{linkStart}see the documentation%{linkEnd}.`,
        ),
        {
          linkStart: `<a href="${this.helpUrl}" target="_blank" rel="noopener noreferer">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
  trackingActions: { ...TrackingActions },
};
</script>

<template>
  <div class="append-bottom-default">
    <gl-tabs @input="trackInstallationTabChange">
      <gl-tab :title="s__('PackageRegistry|Installation')" title-item-class="js-installation-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">{{ s__('PackageRegistry|Conan Command') }}</p>
          <code-instruction
            :instruction="conanCommand"
            :copy-text="s__('PackageRegistry|Copy Conan Command')"
            class="js-conan-command"
            :tracking-action="$options.trackingActions.COPY_CONAN_COMMAND"
          />
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="prepend-left-default append-right-default">
          <p class="prepend-top-8 font-weight-bold">
            {{ s__('PackageRegistry|Add Conan Remote') }}
          </p>
          <code-instruction
            :instruction="setupCommand"
            :copy-text="s__('PackageRegistry|Copy Conan Setup Command')"
            class="js-conan-setup"
            :tracking-action="$options.trackingActions.COPY_CONAN_SETUP_COMMAND"
          />
          <p v-html="helpText"></p>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
