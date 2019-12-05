import Vue from 'vue';
import { createStore } from 'ee/batch_comments/stores';
import { keyboardDownEvent } from 'spec/issue_show/helpers';
import { noteableDataMock, discussionMock, notesDataMock } from 'spec/notes/mock_data';
import diffsModule from '~/diffs/store/modules';
import notesModule from '~/notes/stores/modules';
import issueNoteForm from '~/notes/components/note_form.vue';

describe('issue_note_form component', () => {
  let store;
  let vm;
  let props;

  beforeEach(() => {
    const Component = Vue.extend(issueNoteForm);

    store = createStore();
    store.registerModule('diffs', diffsModule());
    store.registerModule('notes', notesModule());
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

  describe('without batch comments', () => {
    it('does not show resolve checkbox', () => {
      expect(vm.$el.querySelector('[data-qa-selector="resolve_review_discussion_checkbox"]')).toBe(
        null,
      );
    });

    describe('on enter', () => {
      it('should add comment when cmd+enter is pressed', () => {
        spyOn(vm, 'handleUpdate').and.callThrough();
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, true));

        expect(vm.handleUpdate).toHaveBeenCalled();
      });

      it('should add comment when ctrl+enter is pressed', () => {
        spyOn(vm, 'handleUpdate').and.callThrough();
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, false, true));

        expect(vm.handleUpdate).toHaveBeenCalled();
      });
    });
  });

  describe('with batch comments', () => {
    beforeEach(done => {
      store
        .dispatch('batchComments/enableBatchComments')
        .then(vm.$nextTick)
        .then(done)
        .catch(done.fail);
    });

    it('shows resolve checkbox', () => {
      expect(
        vm.$el.querySelector('[data-qa-selector="resolve_review_discussion_checkbox"]'),
      ).not.toBe(null);
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

    describe('on enter', () => {
      it('should start review or add to review when cmd+enter is pressed', () => {
        spyOn(vm, 'handleAddToReview').and.callThrough();
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, true));

        expect(vm.handleAddToReview).toHaveBeenCalled();
      });

      it('should start review or add to review when ctrl+enter is pressed', () => {
        spyOn(vm, 'handleAddToReview').and.callThrough();
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, false, true));

        expect(vm.handleAddToReview).toHaveBeenCalled();
      });
    });
  });
});
