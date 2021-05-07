<script>
import { GlLink, GlTable, GlBadge, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import RunnerTags from './runner_tags.vue';
import RunnerTypeBadge from './runner_type_badge.vue';

const DEFAULT_CELL_CLASSES = 'gl-py-5! gl-px-1!';
const DEFAULT_TH_CLASSES =
  'gl-bg-transparent! gl-border-b-solid! gl-border-b-gray-100! gl-py-5! gl-px-0! gl-border-b-1!';
const thClass = (width = 10) => `gl-w-${width}p ${DEFAULT_TH_CLASSES}`;
const tdClass = () => `${DEFAULT_CELL_CLASSES}`;

export default {
  components: {
    GlBadge,
    GlLink,
    GlTable,
    GlSkeletonLoader,
    TimeAgo,
    TooltipOnTruncate,
    RunnerTags,
    RunnerTypeBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    runners: {
      type: Array,
      required: true,
    },
  },
  methods: {
    runnerNumbericalId(runnerId) {
      return getIdFromGraphQLId(runnerId);
    },
    runnerUrl(runnerId) {
      // TODO implement using webUrl from the API
      return `${gon.gitlab_url}/admin/runners/${getIdFromGraphQLId(runnerId)}`;
    },
  },
  fields: [
    {
      key: 'type_state',
      label: __('Type/State'),
      thClass: thClass(),
      tdClass: tdClass(),
    },
    {
      key: 'name',
      label: s__('Runners|Runner'),
      thClass: thClass(30),
      tdClass: tdClass(),
    },
    {
      key: 'version',
      label: __('Version'),
      thClass: thClass(),
      tdClass: tdClass(),
    },
    {
      key: 'ipAddress',
      label: __('IP Address'),
      thClass: thClass(),
      tdClass: tdClass(),
    },
    {
      key: 'projectCount',
      label: __('Projects'),
      thClass: thClass(5),
      tdClass: tdClass(),
    },
    {
      key: 'jobCount',
      label: __('Jobs'),
      thClass: thClass(5),
      tdClass: tdClass(),
    },
    {
      key: 'tagList',
      label: __('Tags'),
      thClass: thClass(),
      tdClass: tdClass(),
    },
    {
      key: 'contactedAt',
      label: __('Last contact'),
      thClass: thClass(),
      tdClass: tdClass(),
    },
    {
      key: 'actions',
      label: '',
      thClass: thClass(),
      tdClass: tdClass(),
    },
  ],
};
</script>
<template>
  <div v-if="loading || runners">
    <gl-table :busy="loading" :items="runners" :fields="$options.fields" stacked="md" fixed>
      <template #table-busy>
        <gl-skeleton-loader />
      </template>

      <template #cell(type_state)="{ item: { runnerType, locked, active } }">
        <runner-type-badge :type="runnerType" size="sm" />

        <gl-badge v-if="locked" variant="warning" size="sm">
          {{ __('locked') }}
        </gl-badge>

        <gl-badge v-if="!active" variant="danger" size="sm">
          {{ __('paused') }}
        </gl-badge>
      </template>

      <template #cell(name)="{ item: { id, shortSha, description } }">
        <!-- TODO add link -->
        <gl-link :href="runnerUrl(id)"> #{{ runnerNumbericalId(id) }} ({{ shortSha }})</gl-link>
        <tooltip-on-truncate class="gl-display-block" :title="description" truncate-target="child">
          <div class="gl-text-truncate">
            {{ description }}
          </div>
        </tooltip-on-truncate>
      </template>

      <template #cell(version)="{ item: { version, revision } }">
        {{ version }}
      </template>

      <template #cell(projectCount)>
        <!-- TODO add projects count -->
      </template>

      <template #cell(jobCount)>
        <!-- TODO add jobs count -->
      </template>

      <template #cell(tagList)="{ item: { tagList } }">
        <runner-tags :tag-list="tagList" />
      </template>

      <template #cell(ipAddress)="{ item: { ipAddress } }">
        {{ ipAddress }}
      </template>

      <template #cell(contactedAt)="{ item: { contactedAt } }">
        <time-ago v-if="contactedAt" :time="contactedAt" />
        <template v-else>{{ __('Never') }}</template>
      </template>

      <template #cell(actions)>
        <!-- TODO add actions to update runners -->
      </template>
    </gl-table>

    <!-- TODO implement pagination -->
  </div>
</template>
