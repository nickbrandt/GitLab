import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import RequirementsRoot from './components/requirements_root.vue';

import { FilterState } from './constants';

Vue.use(VueApollo);

export default () => {
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
      const {
        filterBy,
        page,
        next,
        prev,
        projectPath,
        emptyStatePath,
        opened,
        archived,
      } = el.dataset;
      const stateFilterBy = filterBy ? FilterState[filterBy] : FilterState.opened;

      const OPENED = parseInt(opened, 10);
      const ARCHIVED = parseInt(archived, 10);

      return {
        filterBy: stateFilterBy,
        requirementsCount: {
          OPENED,
          ARCHIVED,
          ALL: OPENED + ARCHIVED,
        },
        page,
        prev,
        next,
        emptyStatePath,
        projectPath,
      };
    },
    render(createElement) {
      return createElement('requirements-root', {
        props: {
          projectPath: this.projectPath,
          filterBy: this.filterBy,
          requirementsCount: this.requirementsCount,
          page: parseInt(this.page, 10) || 1,
          prev: this.prev,
          next: this.next,
          emptyStatePath: this.emptyStatePath,
        },
      });
    },
  });
};
