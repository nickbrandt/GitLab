<script>
import { __ } from '~/locale';
import $ from 'jquery';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import Api from '~/api';

export default {
  name: 'GroupsDropdownFilter',
  components: {
    Icon,
    GlLoadingIcon,
    GlButton,
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
      clicked: this.onClick,
      data: this.fetchData,
      renderRow: group => this.rowTemplate(group),
      text: group => group.name,
    });
  },
  methods: {
    onClick({ $el, e }) {
      e.preventDefault();
      this.selectedGroup = {
        id: $el.data('id'),
        name: $el.data('name'),
        path: $el.data('path'),
      };
      this.$emit('selected', this.selectedGroup);
    },
    fetchData(term, callback) {
      this.loading = true;
      return Api.groups(term, {}, groups => {
        this.loading = false;
        callback(groups);
      });
    },
    rowTemplate(group) {
      return `
            <li>
              <a href='#' class='dropdown-menu-link' data-id="${group.id}" data-name="${
        group.name
      }" data-path="${group.path}">
                ${_.escape(group.name)}
              </a>
            </li>
          `;
    },
  },
};
</script>

<template>
  <div>
    <div ref="groupsDropdown" class="dropdown dropdown-groups">
      <gl-button
        class="dropdown-menu-toggle wide shadow-none bg-white"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
      >
        {{ selectedGroupName }} <icon name="chevron-down" />
      </gl-button>
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
