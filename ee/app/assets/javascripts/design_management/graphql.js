import Vue from 'vue';
import VueApollo from 'vue-apollo';
import _ from 'underscore';
import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const defaultClient = createDefaultClient(
  {},
  // This config is added temporarily to resolve an issue with duplicate design IDs.
  // Should be removed as soon as https://gitlab.com/gitlab-org/gitlab/issues/13495 is resolved
  {
    cacheConfig: {
      dataIdFromObject: object => {
        // eslint-disable-next-line no-underscore-dangle, @gitlab/i18n/no-non-i18n-strings
        if (object.__typename === 'Design') {
          return object.id && object.image ? `${object.id}-${object.image}` : _.uniqueId();
        }
        return defaultDataIdFromObject(object);
      },
    },
  },
);

export default new VueApollo({
  defaultClient,
});
