<script>
import { mapState } from 'vuex';
<<<<<<< HEAD
=======
import { isEmpty, pick } from 'lodash';
>>>>>>> 4f2acbcae90 (Move job details into own component)
import DetailRow from './sidebar_detail_row.vue';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';

export default {
  name: 'SidebarJobDetailsContainer',
  components: {
    DetailRow,
  },
  mixins: [timeagoMixin],
  props: {
    runnerHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['job']),
    coverage() {
      return `${this.job.coverage}%`;
    },
    duration() {
      return timeIntervalInWords(this.job.duration);
    },
    erasedAt() {
      return this.timeFormatted(this.job.erased_at);
    },
    finishedAt() {
      return this.timeFormatted(this.job.finished_at);
    },
    hasTags() {
      return this.job?.tags?.length;
    },
    hasTimeout() {
<<<<<<< HEAD
      return this.job?.metadata?.timeout_human_readable ?? false;
    },
    hasAnyDetail() {
      return Boolean(
        this.job.duration ||
          this.job.finished_at ||
          this.job.erased_at ||
          this.job.queued ||
          this.job.runner ||
          this.job.coverage,
=======
      return Boolean(this.job?.metadata?.timeout_human_readable);
    },
    hasAnyDetail() {
      return !isEmpty(
        pick(this.job, ['duration', 'finished_at', 'erased_at', 'queued', 'runner', 'coverage']),
>>>>>>> 4f2acbcae90 (Move job details into own component)
      );
    },
    queued() {
      return timeIntervalInWords(this.job.queued);
    },
<<<<<<< HEAD
    runnerId() {
      return `${this.job.runner.description} (#${this.job.runner.id})`;
    },
    shouldRenderBlock() {
      return Boolean(this.hasAnyDetail || this.hasTimeout || this.hasTags);
    },
    timeout() {
      return `${this.job?.metadata?.timeout_human_readable}${this.timeoutSource}`;
    },
    timeoutSource() {
      if (!this.job?.metadata?.timeout_source) {
        return '';
      }

      return sprintf(__(` (from %{timeoutSource})`), {
        timeoutSource: this.job.metadata.timeout_source,
      });
=======
    renderBlock() {
      return this.hasAnyDetail || this.hasTimeout || this.hasTags;
    },
    runnerId() {
      return `${this.job.runner.description} (#${this.job.runner.id})`;
    },
    timeout() {
      if (this.job.metadata == null) {
        return '';
      }

      let t = this.job.metadata.timeout_human_readable;
      if (this.job.metadata.timeout_source !== '') {
        t += sprintf(__(` (from %{timeoutSource})`), {
          timeoutSource: this.job.metadata.timeout_source,
        });
      }

      return t;
>>>>>>> 4f2acbcae90 (Move job details into own component)
    },
  },
};
</script>

<template>
<<<<<<< HEAD
  <div v-if="shouldRenderBlock" class="block">
    <detail-row v-if="job.duration" :value="duration" title="Duration" />
=======
  <div v-if="renderBlock" class="block">
    <detail-row v-if="job.duration" :value="duration" data-testid="job-duration" title="Duration" />
>>>>>>> 4f2acbcae90 (Move job details into own component)
    <detail-row
      v-if="job.finished_at"
      :value="finishedAt"
      data-testid="job-finished"
      title="Finished"
    />
<<<<<<< HEAD
    <detail-row v-if="job.erased_at" :value="erasedAt" title="Erased" />
    <detail-row v-if="job.queued" :value="queued" title="Queued" />
=======
    <detail-row v-if="job.erased_at" :value="erasedAt" data-testid="job-erased" title="Erased" />
    <detail-row v-if="job.queued" :value="queued" data-testid="job-queued" title="Queued" />
>>>>>>> 4f2acbcae90 (Move job details into own component)
    <detail-row
      v-if="hasTimeout"
      :help-url="runnerHelpUrl"
      :value="timeout"
      data-testid="job-timeout"
      title="Timeout"
    />
<<<<<<< HEAD
    <detail-row v-if="job.runner" :value="runnerId" title="Runner" />
    <detail-row v-if="job.coverage" :value="coverage" title="Coverage" />
=======
    <detail-row v-if="job.runner" :value="runnerId" data-testid="job-runner" title="Runner" />
    <detail-row v-if="job.coverage" :value="coverage" data-testid="job-coverage" title="Coverage" />
>>>>>>> 4f2acbcae90 (Move job details into own component)

    <p v-if="hasTags" class="build-detail-row" data-testid="job-tags">
      <span class="font-weight-bold">{{ __('Tags:') }}</span>
      <span v-for="(tag, i) in job.tags" :key="i" class="badge badge-primary mr-1">{{ tag }}</span>
    </p>
  </div>
</template>
