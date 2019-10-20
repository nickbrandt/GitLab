<script>
import { mapState, mapGetters, mapActions } from 'vuex';

import { GlButton, GlTooltip } from '@gitlab/ui';

import { sprintf, s__ } from '~/locale';

import Icon from '~/vue_shared/components/icon.vue';
import DroplabDropdownButton from '~/vue_shared/components/droplab_dropdown_button.vue';

import { EpicDropdownActions } from '../constants';

export default {
  EpicDropdownActions,
  components: {
    Icon,
    GlButton,
    GlTooltip,
    DroplabDropdownButton,
  },
  computed: {
    ...mapGetters(['headerItems']),
    ...mapState(['parentItem']),
  },
  methods: {
    ...mapActions(['toggleAddItemForm', 'toggleCreateEpicForm']),
    handleActionClick({ id, issuableType }) {
      if (id === 0) {
        this.toggleAddItemForm({
          issuableType,
          toggleState: true,
        });
      } else {
        this.toggleCreateEpicForm({ toggleState: true });
      }
    },
  },
};
</script>

<template>
  <div class="card-header d-flex px-2">
    <div class="d-inline-flex flex-grow-1 lh-100 align-middle">
      <gl-tooltip :target="() => $refs.countBadge">
        <p class="font-weight-bold m-0">
          {{ __('Epics') }} &#8226;
          <span class="text-secondary-400 font-weight-normal"
            >{{
              sprintf(__('%{openEpics} open, %{closedEpics} closed'), {
                openEpics: headerItems[0].count.open,
                closedEpics: headerItems[0].count.closed,
              })
            }}
          </span>
        </p>
        <p class="font-weight-bold m-0">
          {{ __('Issues') }} &#8226;
          <span class="text-secondary-400 font-weight-normal"
            >{{
              sprintf(__('%{openIssues} open, %{closedIssues} closed'), {
                openIssues: headerItems[1].count.open,
                closedIssues: headerItems[1].count.closed,
              })
            }}
          </span>
        </p>
      </gl-tooltip>
      <div ref="countBadge" class="issue-count-badge">
        <span
          v-for="(item, index) in headerItems"
          :key="index"
          :class="{ 'ml-2': index }"
          class="d-inline-flex align-items-center"
        >
          <icon :size="16" :name="item.iconName" class="text-secondary mr-1" />
          {{ item.count.total }}
        </span>
      </div>
    </div>
    <div class="d-inline-flex">
      <template v-if="parentItem.userPermissions.adminEpic">
        <droplab-dropdown-button
          :actions="$options.EpicDropdownActions"
          :default-action="0"
          :primary-button-class="`${headerItems[0].qaClass} js-add-epics-button`"
          class="btn-create-epic"
          size="sm"
          @onActionClick="handleActionClick"
        />
        <gl-button
          :class="headerItems[1].qaClass"
          class="ml-1 js-add-issues-button"
          size="sm"
          @click="handleActionClick({ id: 0, issuableType: 'issue' })"
          >{{ __('Add an issue') }}</gl-button
        >
      </template>
    </div>
  </div>
</template>
