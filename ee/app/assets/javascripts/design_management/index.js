import $ from 'jquery';
import Vue from 'vue';
import createRouter from './router';
import App from './components/app.vue';
import apolloProvider from './graphql';
import projectQuery from './graphql/queries/project.query.graphql';

export default () => {
  const el = document.getElementById('js-design-management');
  const badge = document.querySelector('.js-designs-count');
  const { issueIid, projectPath, issuePath } = el.dataset;
  const router = createRouter(issuePath);

  $('.js-issue-tabs').on('shown.bs.tab', ({ target: { id } }) => {
    if (id === 'designs' && router.currentRoute.name === 'root') {
      router.push('/designs');
    } else if (id === 'discussion') {
      router.push('/');
    }
  });

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      projectPath,
      issueIid,
    },
  });

  apolloProvider.clients.defaultClient
    .watchQuery({
      query: projectQuery,
      variables: {
        fullPath: projectPath,
        iid: issueIid,
        atVersion: null,
      },
    })
    .subscribe(({ data }) => {
      if (badge) {
        badge.textContent = data.project.issue.designCollection.designs.edges.length;
      }
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
