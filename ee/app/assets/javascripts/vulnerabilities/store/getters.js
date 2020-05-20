import { keyBy } from 'lodash';

export const discussions = state => Object.values(state.discussionsDictionary);

export const notesDictionary = (state, getters) =>
  keyBy(getters.discussions.flatMap(x => x.notes), 'id');
