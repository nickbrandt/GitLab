import Vue from 'vue';
import VueApollo from 'vue-apollo';
import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';
import SnippetBlobContent from 'shared_queries/snippet/snippet_blob_content.query.graphql';
import CanCreatePersonalSnippet from 'shared_queries/snippet/user_permissions.query.graphql';
import CanCreateProjectSnippet from 'shared_queries/snippet/project_permissions.query.graphql';

import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';

import { SNIPPET_LEVELS_MAP, SNIPPET_VISIBILITY_PRIVATE } from '~/snippets/constants';

Vue.use(VueApollo);
Vue.use(Translate);

export default function appFactory(el, Component) {
  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { batchMax: 1 }),
  });

  const {
    visibilityLevels = '[]',
    selectedLevel,
    multipleLevelsRestricted,
    ...restDataset
  } = el.dataset;

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      visibilityLevels: JSON.parse(visibilityLevels),
      selectedLevel: SNIPPET_LEVELS_MAP[selectedLevel] ?? SNIPPET_VISIBILITY_PRIVATE,
      multipleLevelsRestricted: 'multipleLevelsRestricted' in el.dataset,
    },
  });

  const initApp = () =>
    new Vue({
      el,
      apolloProvider,
      render(createElement) {
        return createElement(Component, {
          props: {
            ...restDataset,
          },
        });
      },
    });

  if (window.gl.startup_graphql_calls) {
    const names = ['GetSnippetQuery', 'SnippetBlobContent', el.dataset.projectId? 'CanCreateProjectSnippet': 'CanCreatePersonalSnippet'];
    const queries = [];
    names.forEach(name => {
      queries.push(
        window.gl.startup_graphql_calls.find(call => call.operationName === name).fetchCall,
      );
    });
    if (queries.length) {
      Promise.all(queries)
        .then(([snippetRes, contentRes, permissionsRes]) =>
          Promise.all([snippetRes.json(), contentRes.json(), permissionsRes.json()]),
        )
        .then(([snippet, content, permissions]) => {
          apolloProvider.clients.defaultClient.writeQuery({
            query: GetSnippetQuery,
            data: snippet.data,
            variables: {
              ids: [el.dataset.snippetGid],
            },
          });
          apolloProvider.clients.defaultClient.writeQuery({
            query: SnippetBlobContent,
            data: content.data,
            variables: {
              ids: [el.dataset.snippetGid],
              rich: false,
              paths: [el.dataset.firstFileName],
            },
          });
          if (el.dataset.projectId) {
            apolloProvider.clients.defaultClient.writeQuery({
              query: CanCreateProjectSnippet,
              data: permissions.data,
              variables: {
                fullPath: el.dataset.projectId,
              },
            });
          } else {
            apolloProvider.clients.defaultClient.writeQuery({
              query: CanCreatePersonalSnippet,
              data: permissions.data,
            });
          }
        })
        .catch(() => {})
        .finally(() => initApp());
    } else {
      initApp();
    }
  } else {
    initApp();
  }

  return true;
}
