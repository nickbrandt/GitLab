import Vue from 'vue';
import App from './components/app.vue';

export default el => {
  if (!el) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: { App },
    data() {
      const { members, groupId, currentUserId } = this.$options.el.dataset;

      return {
        members: JSON.parse(members),
        groupId: parseInt(groupId, 10),
        ...(currentUserId ? { currentUserId: parseInt(currentUserId, 10) } : {}),
      };
    },
    render(createElement) {
      return createElement('app', {
        props: {
          members: this.members,
          groupId: this.groupId,
          currentUserId: this.currentUserId,
        },
      });
    },
  });
};
