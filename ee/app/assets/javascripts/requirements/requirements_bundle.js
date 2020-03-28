import Vue from 'vue';

import RequirementsRoot from './components/requirements_root.vue';

import { FilterState } from './constants';

export default () => {
  const btnNewRequirement = document.querySelector('.js-new-requirement');
  const el = document.getElementById('js-requirements-app');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    components: {
      RequirementsRoot,
    },
    data() {
      return {
        showCreateRequirement: false,
        filterBy: el?.dataset?.filterBy || FilterState.Open,
      };
    },
    mounted() {
      btnNewRequirement.addEventListener('click', this.handleClickNewRequirement);
    },
    beforeDestroy() {
      btnNewRequirement.removeEventListener('click', this.handleClickNewRequirement);
    },
    methods: {
      handleClickNewRequirement() {
        this.showCreateRequirement = !this.showCreateRequirement;
      },
    },
    render(createElement) {
      return createElement('requirements-root', {
        props: {
          filterBy: this.filterBy,
          showCreateRequirement: this.showCreateRequirement,
        },
      });
    },
  });
};
