import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CorpusManagement from './components/corpus_management.vue';
import resolvers from './graphql/resolvers/resolvers';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('.js-corpus-management');

  if (!el) {
    return undefined;
  }

  const defaultClient = createDefaultClient(resolvers, {
    cacheConfig: {
      dataIdFromObject: (object) => {
        return object.id || defaultDataIdFromObject(object);
      },
    },
  });

  const {
    dataset: { projectFullPath },
  } = el;

  // TODO: Remove when we ship, this is for high fidelity mocks demo.
  let {
    dataset: { corpusHelpPath },
  } = el;

  corpusHelpPath = 'https://docs.gitlab.com/ee/user/application_security/coverage_fuzzing/';

  const provide = {
    projectFullPath,
    corpusHelpPath,
  };

  return new Vue({
    el,
    provide,
    apolloProvider: new VueApollo({ defaultClient }),
    render(h) {
      return h(CorpusManagement, {});
    },
  });
};
