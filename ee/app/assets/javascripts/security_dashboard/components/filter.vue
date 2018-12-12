<script>
import { mapGetters, mapMutations } from 'vuex';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import Help from './help.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    Help,
    Icon,
  },
  props: {
    filterId: {
      type: String,
      required: true,
    },
    dashboardDocumentation: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('filters', ['getFilter', 'getSelectedOptions']),
    filter() {
      return this.getFilter(this.filterId);
    },
    selectedOptionText() {
      const selectedOption = this.getSelectedOptions(this.filterId)[0];
      return (selectedOption && selectedOption.name) || '-';
    },
  },
  methods: {
    ...mapMutations('filters', ['SET_FILTER']),
    clickFilter(option) {
      const { filterId } = this;
      const optionId = option.id;
      this.SET_FILTER({ filterId, optionId });
      this.$emit('change');
    },
  },
};
</script>

<template>
  <div class="dashboard-filter">
    <strong class="js-name">{{ filter.name }}</strong>
    <help v-if="filterId === 'type'" :dashboard-documentation="dashboardDocumentation" />
    <gl-dropdown :text="selectedOptionText" class="d-block mt-1">
      <gl-dropdown-item
        v-for="option in filter.options"
        :key="option.id"
        @click="clickFilter(option);"
      >
        <icon
          v-if="option.selected"
          class="vertical-align-middle js-check"
          name="mobile-issue-close"
        />
        <span class="vertical-align-middle" :class="{ 'prepend-left-20': !option.selected }">{{
          option.name
        }}</span>
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>

<style>
.dashboard-filter .dropdown-toggle {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
</style>
