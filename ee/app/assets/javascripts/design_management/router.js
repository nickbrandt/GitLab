import $ from 'jquery';
import Vue from 'vue';
import VueRouter from 'vue-router';
import Home from './pages/index.vue';
import DesignDetail from './pages/design/index.vue';

Vue.use(VueRouter);

export default function createRouter(base) {
  const router = new VueRouter({
    base,
    mode: 'history',
    routes: [
      {
        name: 'root',
        path: '/',
        component: Home,
        meta: {
          el: 'discussion',
        },
      },
      {
        name: 'designs',
        path: '/designs',
        component: Home,
        meta: {
          el: 'designs',
        },
        children: [
          {
            name: 'design',
            path: ':id',
            component: DesignDetail,
            meta: {
              el: 'designs',
            },
            beforeEnter(
              {
                params: { id },
              },
              from,
              next,
            ) {
              if (typeof id === 'string') {
                next();
              }
            },
            props: ({ params: { id } }) => ({ id }),
          },
        ],
      },
    ],
  });

  router.beforeEach(({ meta: { el } }, from, next) => {
    $(`#${el}`).tab('show');

    next();
  });

  return router;
}
