import $ from 'jquery';
import Vue from 'vue';
import VueRouter from 'vue-router';
import Home from './pages/index.vue';
import DesignDetail from './pages/design/index.vue';

Vue.use(VueRouter);

const router = new VueRouter({
  base: window.location.pathname,
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
            if (id !== -1) next();
          },
          props: ({ params: { id } }) => ({ id: parseInt(id, 10) }),
        },
      ],
    },
  ],
});

router.beforeEach(({ meta: { el } }, from, next) => {
  $(`#${el}`).tab('show');

  next();
});

export default router;
