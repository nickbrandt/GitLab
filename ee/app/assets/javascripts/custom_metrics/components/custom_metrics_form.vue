<script>
import { GlFormInput, GlButton, GlLink, GlFormGroup } from '@gitlab/ui';
import _ from 'underscore';
import { __, s__ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import Icon from '~/vue_shared/components/icon.vue';
import axios from '~/lib/utils/axios_utils';
import DeleteCustomMetricModal from './delete_custom_metric_modal.vue';
import QueryTypes from '../constants';

export default {
  components: {
    DeleteCustomMetricModal,
    GlFormInput,
    GlButton,
    GlLink,
    GlFormGroup,
    Icon,
  },
  props: {
    customMetricsPath: {
      type: String,
      required: false,
      default: '',
    },
    metricPersisted: {
      type: Boolean,
      required: true,
    },
    editProjectServicePath: {
      type: String,
      required: true,
    },
    validateQueryPath: {
      type: String,
      required: true,
    },
    formData: {
      type: Object,
      required: true,
      validator: val => {
        const fieldNames = Object.keys(val);
        const requiredFields = ['title', 'query', 'yLabel', 'unit', 'group', 'legend'];

        return requiredFields.every(name => fieldNames.includes(name));
      },
    },
  },
  data() {
    return {
      validCustomQuery: null,
      errorMessage: '',
    };
  },
  computed: {
    disabledForm() {
      return this.validCustomQuery;
    },
    saveButtonText() {
      return this.metricPersisted ? __('Save Changes') : s__('Metrics|Create metric');
    },
    titleText() {
      return this.metricPersisted ? s__('Metrics|Edit metric') : s__('Metrics|New metric');
    },
    validQueryMsg() {
      return this.validCustomQuery ? s__('Metrics|PromQL query is valid') : '';
    },
    invalidQueryMsg() {
      return !this.validCustomQuery ? this.errorMessage : '';
    },
  },
  created() {
    this.csrf = csrf.token != null ? csrf.token : '';
    this.formOperation = this.metricPersisted ? 'patch' : 'post';
    this.formData.group = this.formData.group.length ? this.formData.group : QueryTypes.business;

    if (this.metricPersisted) {
      this.validate();
    }
  },
  methods: {
    submit() {
      this.$refs.form.submit();
    },
    validate() {
      this.requestValidation()
        .then(res => {
          const response = res.data;
          const { valid, error } = response.query;

          if (response.success) {
            this.errorMessage = valid ? '' : error;
            this.validCustomQuery = valid;
          } else {
            throw new Error('There was an error trying to validate your query');
          }
        })
        .catch(() => {
          this.errorMessage = s__('Metrics|There was an error trying to validate your query');
          this.validCustomQuery = false;
        });
    },
    validateQuery: _.debounce(function debounceValidateQuery() {
      this.validate();
    }, 500),
    requestValidation() {
      return axios.post(this.validateQueryPath, {
        query: this.formData.query,
      });
    },
  },
  QueryTypes,
};
</script>
<template>
  <div class="row my-3">
    <h4 class="text-center prepend-top-0">{{ titleText }}</h4>
    <form ref="form" class="col-lg-8 offset-lg-2" :action="customMetricsPath" method="post">
      <input ref="method" type="hidden" name="_method" :value="formOperation" />
      <input :value="csrf" type="hidden" name="authenticity_token" />
      <gl-form-group
        :label="__('Name')"
        label-for="prometheus_metric_title"
        label-class="label-bold"
      >
        <gl-form-input
          id="prometheus_metric_title"
          v-model="formData.title"
          :value="formData.title"
          name="prometheus_metric[title]"
          class="form-control"
          :placeholder="s__('Metrics|e.g. Throughput')"
          required
        />
        <span class="form-text text-muted">{{ s__('Metrics|Used as a title for the chart') }}</span>
      </gl-form-group>
      <gl-form-group
        :label="__('Type')"
        label-for="prometheus_metric_group"
        label-class="label-bold"
      >
        <input
          id="group-business"
          v-model="formData.group"
          type="radio"
          name="prometheus_metric[group]"
          :value="$options.QueryTypes.business"
        />
        <label class="label-bold append-right-10" for="group-business">{{ __('Business') }}</label>
        <input
          id="group-response"
          v-model="formData.group"
          type="radio"
          name="prometheus_metric[group]"
          :value="$options.QueryTypes.response"
        />
        <label class="label-bold append-right-10" for="group-response">{{ __('Response') }}</label>
        <input
          id="group-system"
          v-model="formData.group"
          type="radio"
          name="prometheus_metric[group]"
          :value="$options.QueryTypes.system"
        />
        <label class="label-bold" for="group-system">{{ s__('Metrics|System') }}</label>
        <span class="form-text text-muted">{{ s__('Metrics|For grouping similar metrics') }}</span>
      </gl-form-group>
      <gl-form-group
        :label="__('Query')"
        label-for="prometheus_metric_query"
        label-class="label-bold"
        :state="validCustomQuery"
      >
        <gl-form-input
          id="prometheus_metric_query"
          v-model="formData.query"
          :value="formData.query"
          name="prometheus_metric[query]"
          class="form-control"
          placeholder="e.g. rate(http_requests_total[5m])"
          required
          :state="validCustomQuery"
          @input="validateQuery"
        />
        <slot name="valid-feedback">
          <span class="form-text cgreen">
            {{ validQueryMsg }}
          </span>
        </slot>
        <slot name="invalid-feedback">
          <span class="form-text cred">
            {{ invalidQueryMsg }}
          </span>
        </slot>
        <span v-show="formData.query.length === 0" class="form-text text-muted">
          {{ s__('Metrics|Must be a valid PromQL query.') }}
          <gl-link
            href="https://prometheus.io/docs/prometheus/latest/querying/basics/"
            tabindex="-1"
          >
            {{ s__('Metrics|Prometheus Query Documentation') }}
            <icon name="external-link" :size="12" />
          </gl-link>
        </span>
      </gl-form-group>
      <gl-form-group
        :label="s__('Metrics|Y-axis label')"
        label-for="prometheus_metric_y_label"
        label-class="label-bold"
      >
        <gl-form-input
          id="prometheus_metric_y_label"
          v-model="formData.yLabel"
          :value="formData.yLabel"
          name="prometheus_metric[y_label]"
          class="form-control"
          placeholder="e.g. Requests/second"
          required
        />
        <span class="form-text text-muted">
          {{
            s__(
              'Metrics|Label of the y-axis (usually the unit). The x-axis always represents time.',
            )
          }}
        </span>
      </gl-form-group>
      <gl-form-group
        :label="s__('Metrics|Unit label')"
        label-for="prometheus_metric_unit"
        label-class="label-bold"
      >
        <gl-form-input
          id="prometheus_metric_unit"
          v-model="formData.unit"
          :value="formData.unit"
          name="prometheus_metric[unit]"
          class="form-control"
          placeholder="e.g. req/sec"
          required
        />
      </gl-form-group>
      <gl-form-group
        :label="s__('Metrics|Legend label (optional)')"
        label-for="prometheus_metric_legend"
        label-class="label-bold"
      >
        <gl-form-input
          id="prometheus_metric_legend"
          v-model="formData.legend"
          :value="formData.legend"
          name="prometheus_metric[legend]"
          class="form-control"
          placeholder="e.g. HTTP requests"
          required
        />
        <span class="form-text text-muted">
          {{
            s__(
              'Metrics|Used if the query returns a single series. If it returns multiple series, their legend labels will be picked up from the response.',
            )
          }}
        </span>
      </gl-form-group>
      <div class="form-actions">
        <gl-button variant="success" :disabled="!disabledForm" @click="submit">
          {{ saveButtonText }}
        </gl-button>
        <gl-button variant="secondary" class="float-right" :href="editProjectServicePath">{{
          __('Cancel')
        }}</gl-button>
        <delete-custom-metric-modal
          v-if="metricPersisted"
          :delete-metric-url="customMetricsPath"
          :csrf-token="csrf"
        />
      </div>
    </form>
  </div>
</template>
