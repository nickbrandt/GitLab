import App from 'ee/vulnerability_management/components/app.vue';
import Vue from 'vue';

window.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('vulnerability-show-header');
  const { state, id } = el.dataset;

  return new Vue({
    el,

    render: h => h(App, { props: { state, id: Number(id) } }),
  });
});
