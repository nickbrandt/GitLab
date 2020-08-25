import Vue from 'vue';
import VueRouter from 'vue-router';
import routes from './routes';
import { DESIGN_ROUTE_NAME } from './constants';
import {
  getPageLayoutElement,
  toDiffNoteGid,
} from '~/design_management/utils/design_management_utils';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '../constants';
import updateActiveDiscussionMutation from '../graphql/mutations/update_active_discussion.mutation.graphql';

Vue.use(VueRouter);

export default function createRouter(base, apolloClient) {
  const router = new VueRouter({
    base,
    mode: 'history',
    routes,
  });
  const pageEl = getPageLayoutElement();

  router.beforeEach(({ name, hash }, _, next) => {
    // apply a fullscreen layout style in Design View (a.k.a design detail)
    if (pageEl) {
      if (name === DESIGN_ROUTE_NAME) {
        pageEl.classList.add(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
      } else {
        pageEl.classList.remove(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
      }
    }

    if (name === DESIGN_ROUTE_NAME) {
      const [, noteId] = hash.match(/#note_([0-9]+)/) || [];
      const diffNoteGid = noteId ? toDiffNoteGid(noteId) : undefined;

      apolloClient.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id: diffNoteGid,
          source: null,
        },
      });
    }

    next();
  });

  return router;
}
