<script>
import { __ } from '~/locale';
import $ from 'jquery';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import Api from '~/api';

export default {
  name: 'GroupsDropdownFilter',
  components: {
    Icon,
    GlLoadingIcon,
  },
  props: {
  },
  data() {
    return {
      loading: true,
      selectedGroup: {},
    };
  },
  computed: {
    selectedGroupName() {
      return this.selectedGroup.name || __('Choose a group');
    },
  },
  mounted() {
    $(this.$refs.groupsDropdown).glDropdown({
      selectable: true,
      filterable: true,
      filterRemote: true,
      fieldName: 'group_id',
      search: {
        fields: ['full_name'],
      },
      clicked: ({ $el, e }) => {
        e.preventDefault();
        this.selectedGroup = {
          id: $el.data('group-id'),
          name: $el.data('group-name'),
          path: $el.data('group-path'),
        };
        this.$emit('set-selected-group', this.selectedGroup);
      },
      data: (term, callback) => {
        this.loading = true;
        return Api.groups(
          term,
          {},
          groups => {
            this.loading = false;
            callback(groups);
          },
        );
      },
      renderRow(group) {
        return `
            <li>
              <a href='#' class='dropdown-menu-link' data-group-id="${
                group.id
              }" data-group-name="${group.name}" data-group-path="${group.path}">
                ${_.escape(group.name)}
              </a>
            </li>
          `;
      },
      text: group => group.name,
    });
  },
};
</script>

<template>
  <div>
    <div ref="groupsDropdown" class="dropdown dropdown-groups">
      <button
        class="dropdown-menu-toggle wide"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
      >
        {{ selectedGroupName }} <icon name="chevron-down" />
      </button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
        <div class="dropdown-title">{{ __('Groups') }}</div>
        <div class="dropdown-input">
          <input class="dropdown-input-field" type="search" :placeholder="__('Search groups')" />
          <icon name="search" class="dropdown-input-search" data-hidden="true" />
        </div>
        <div class="dropdown-content"></div>
        <div class="dropdown-loading"><gl-loading-icon /></div>
      </div>
    </div>
  </div>
</template>
