import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
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
    defaultClient: createDefaultClient(
      {},
      {
        cacheConfig: {
          dataIdFromObject: object =>
            // eslint-disable-next-line no-underscore-dangle, @gitlab/require-i18n-strings
            object.__typename === 'Requirement' ? object.iid : defaultDataIdFromObject(object),
        },
      },
    ),
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
        all,
        requirementsWebUrl,
      } = el.dataset;
      const stateFilterBy = filterBy ? FilterState[filterBy] : FilterState.opened;

      const OPENED = parseInt(opened, 10);
      const ARCHIVED = parseInt(archived, 10);
      const ALL = parseInt(all, 10);

      return {
        filterBy: stateFilterBy,
        requirementsCount: {
          OPENED,
          ARCHIVED,
          ALL,
        },
        page,
        prev,
        next,
        emptyStatePath,
        projectPath,
        requirementsWebUrl,
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
          requirementsWebUrl: this.requirementsWebUrl,
        },
      });
    },
  });
};
