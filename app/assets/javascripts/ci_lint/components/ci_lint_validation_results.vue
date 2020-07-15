<script>
import { GlAlert, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

const VALID_STATUS = 'true';

export default {
  fields: [
    {
      key: 'parameter',
      label: __('Parameter'),
    },
    {
      key: 'value',
      label: __('Value'),
    },
  ],
  components: {
    GlAlert,
    GlTable,
  },
  props: {
    builds: {
      type: Array,
      required: true,
      default: () => [],
    },
    errors: {
      type: Array,
      required: false,
      default: () => [],
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isValidYAML() {
      return this.status === VALID_STATUS;
    },
    lastErrorIndex() {
      return this.errors.length - 1;
    },
  },
  methods: {
    formatParameterValue({ stage, name }) {
      return __(`${capitalizeFirstCharacter(stage)} Job - ${name}`);
    },
    formatJobText(cmds) {
      return cmds.join('\\n');
    },
    createStrigListFromObject(obj = {}) {
      return Object.entries(obj)
        .flat(2)
        .join(', ');
    },
  },
};
</script>

<template>
  <div class="gl-mt-5 ">
    <div v-if="isValidYAML">
      <gl-alert variant="success" :dismissible="false">
        {{ __('Status: syntax is correct') }}
      </gl-alert>
      <gl-table :items="builds" :fields="$options.fields" class="gl-mt-5">
        <template #cell(parameter)="{ item }">
          <span data-testid="lint-jobname">{{ formatParameterValue(item) }}</span>
        </template>
        <template #cell(value)="{ item }" date-testid="test">
          <pre v-if="item.options.before_script" data-testid="lint-before-script">{{
            formatJobText(item.options.before_script)
          }}</pre>
          <pre data-testid="lint-script">{{ formatJobText(item.options.script) }}</pre>
          <pre v-if="item.options.after_script" data-testid="lint-after-script">{{
            formatJobText(item.options.after_script)
          }}</pre>

          <ul class="gl-list-style-none gl-pl-0 gl-mt-7">
            <li>
              <strong>{{ __('Tag list:') }}</strong>
              {{ item.tag_list.join(', ') }}
            </li>
            <li>
              <strong>{{ __('Only policy:') }}</strong>
              {{ createStrigListFromObject(item.only) }}
            </li>
            <li>
              <strong>{{ __('Except policy:') }}</strong>
              {{ createStrigListFromObject(item.except) }}
            </li>
            <li>
              <strong>{{ __('Environment:') }}</strong>
              {{ item.environment }}
            </li>
            <li>
              <strong>{{ __('When:') }}</strong>
              {{ item.when }}
              <strong v-if="item.allow_failure"> - {{ __('Allowed to fail') }}</strong>
            </li>
          </ul>
        </template>
      </gl-table>
    </div>
    <div v-else>
      <gl-alert variant="danger" :dismissible="false">
        {{ __('Status: syntax is incorrect') }}
      </gl-alert>
      <pre
        class="gl-py-5 gl-mt-5"
        data-testid="lint-error-messages"
      ><p v-for="(error, index) in errors" :key="error" :class="{'gl-mb-0' : index === lastErrorIndex}">{{error}}</p></pre>
    </div>
  </div>
</template>
