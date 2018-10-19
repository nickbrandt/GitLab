import Vue from 'vue';
import { createStore } from '~/mr_notes/stores';
import issueNoteForm from '~/notes/components/note_form.vue';
import { noteableDataMock, discussionMock, notesDataMock } from 'spec/notes/mock_data';

describe('issue_note_form component', () => {
  let store;
  let vm;
  let props;

  beforeEach(() => {
    const Component = Vue.extend(issueNoteForm);

    store = createStore();
    store.dispatch('setNoteableData', noteableDataMock);
    store.dispatch('setNotesData', notesDataMock);

    props = {
      isEditing: false,
      noteBody: 'Magni suscipit eius consectetur enim et ex et commodi.',
      discussion: { ...discussionMock, for_commit: false },
    };

    vm = new Component({
      store,
      propsData: props,
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('with batch comments', () => {
    beforeEach(done => {
      store
        .dispatch('batchComments/enableBatchComments')
        .then(vm.$nextTick)
        .then(done)
        .catch(done.fail);
    });

    it('hides actions for commits', done => {
      vm.discussion.for_commit = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.note-form-actions').textContent).not.toContain(
          'Start a review',
        );

        done();
      });
    });
  });
});
