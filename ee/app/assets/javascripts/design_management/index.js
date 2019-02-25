import $ from 'jquery';
import Vue from 'vue';
import router from './router';
import App from './components/app.vue';
import apolloProvider from './graphql';

export default () => {
  $('.js-issue-tabs').on('shown.bs.tab', ({ target: { id } }) => {
    if (id === 'designs' && router.currentRoute.name === 'root') {
      router.push('/designs');
    } else if (id === 'discussion') {
      router.push('/');
    }
  });

  return new Vue({
    el: document.getElementById('js-design-management'),
    router,
    apolloProvider,
    render(createElement) {
      return createElement(App);
    },
  });
};
