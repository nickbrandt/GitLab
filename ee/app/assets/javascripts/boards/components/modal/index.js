import Vue from 'vue';
import BoardAddIssuesModal from '~/boards/components/modal/index.vue';
import ModalFooter from './footer';

export default Vue.extend(BoardAddIssuesModal, {
  components: {
    ModalFooter,
  },
});
