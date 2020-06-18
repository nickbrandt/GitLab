import Vue from 'vue';
import createRouter from './router';
import App from './components/app.vue';
import apolloProvider from './graphql';

export default () => {
  const el = document.querySelector('.js-design-management');
  const { issueIid, projectPath, issuePath } = el.dataset;
  const router = createRouter(issuePath);

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      projectPath,
      issueIid,
      activeDiscussion: {
        __typename: 'ActiveDiscussion',
        id: null,
        source: null,
      },
    },
  });

  return new Vue({
    el,
    router,
    apolloProvider,
    render(createElement) {
      return createElement(App);
    },
  });
};
