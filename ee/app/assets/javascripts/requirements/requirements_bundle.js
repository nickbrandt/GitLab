import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import RequirementsRoot from './components/requirements_root.vue';

import { FilterState } from './constants';

Vue.use(VueApollo);

export default () => {
  const btnNewRequirement = document.querySelector('.js-new-requirement');
  const el = document.getElementById('js-requirements-app');

  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    components: {
      RequirementsRoot,
    },
    data() {
      const { filterBy, projectPath, emptyStatePath } = el.dataset;
      const stateFilterBy = filterBy ? FilterState[filterBy] : FilterState.opened;

      return {
        showCreateRequirement: false,
        filterBy: stateFilterBy,
        emptyStatePath,
        projectPath,
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
          projectPath: this.projectPath,
          filterBy: this.filterBy,
          showCreateRequirement: this.showCreateRequirement,
          emptyStatePath: this.emptyStatePath,
        },
      });
    },
  });
};
