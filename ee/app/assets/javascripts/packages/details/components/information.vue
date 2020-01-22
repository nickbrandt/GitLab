<script>
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { mapGetters, mapState } from 'vuex';
import { GlIcon, GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'PackageInformation',
  components: {
    ClipboardButton,
    GlIcon,
    GlLoadingIcon,
  },
  props: {
    heading: {
      type: String,
      default: s__('Package information'),
      required: false,
    },
    information: {
      type: Array,
      default: () => [],
      required: true,
    },
    showCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['isLoading', 'pipelineError', 'pipelineInfo']),
    ...mapGetters(['packageHasPipeline']),
    pipelineSha() {
      if (this.pipelineInfo?.sha) {
        return this.pipelineInfo.sha.substring(0, 7);
      }

      return '';
    },
  },
};
</script>

<template>
  <div class="card">
    <div class="card-header">
      <strong>{{ heading }}</strong>
    </div>

    <ul class="content-list">
      <li v-for="(item, index) in information" :key="index">
        <span class="text-secondary">{{ item.label }}</span>
        <div class="pull-right">
          <span>{{ item.value }}</span>
          <clipboard-button
            v-if="showCopy"
            :text="item.value"
            :title="sprintf(__('Copy %{field}'), { field: item.label })"
            css-class="border-0 text-secondary py-0"
          />
        </div>
      </li>
      <li v-if="packageHasPipeline" class="js-package-pipeline">
        <span class="text-secondary">{{ __('Pipeline') }}</span>
        <div class="pull-right">
          <gl-loading-icon v-if="isLoading" class="vertical-align-middle" size="sm" />
          <span v-else-if="pipelineError" class="js-pipeline-error">{{ pipelineError }}</span>
          <span v-else class="js-pipeline-info">
            <a :href="pipelineInfo.web_url" class="append-right-8">#{{ pipelineInfo.id }}</a>
            <gl-icon name="branch" class="append-right-4 vertical-align-middle text-secondary" />
            <a :href="`../../tree/${pipelineInfo.ref}`" class="append-right-8">{{
              pipelineInfo.ref
            }}</a>
            <gl-icon name="commit" class="append-right-4 vertical-align-middle text-secondary" /><a
              :href="`../../commit/${pipelineInfo.sha}`"
              >{{ pipelineSha }}</a
            >
            <clipboard-button
              v-if="pipelineSha"
              :text="pipelineInfo.sha"
              :title="__('Copy commit SHA')"
              css-class="border-0 text-secondary py-0"
            />
          </span>
        </div>
      </li>
    </ul>
  </div>
</template>
