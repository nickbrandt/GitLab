import Vue from 'vue';
import { createStore } from 'ee/batch_comments/stores';
import { keyboardDownEvent } from 'jest/issue_show/helpers';
import { noteableDataMock, discussionMock, notesDataMock } from 'jest/notes/mock_data';
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
        jest.spyOn(vm, 'handleUpdate');
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, true));

        expect(vm.handleUpdate).toHaveBeenCalled();
      });

      it('should add comment when ctrl+enter is pressed', () => {
        jest.spyOn(vm, 'handleUpdate');
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, false, true));

        expect(vm.handleUpdate).toHaveBeenCalled();
      });
    });
  });

  describe('with batch comments', () => {
    beforeEach(() => {
      return store.dispatch('batchComments/enableBatchComments').then(vm.$nextTick);
    });

    it('should be possible to cancel', () => {
      jest.spyOn(vm, 'cancelHandler');

      return vm.$nextTick().then(() => {
        const cancelButton = vm.$el.querySelector('[data-testid="cancelBatchCommentsEnabled"]');
        cancelButton.click();

        expect(vm.cancelHandler).toHaveBeenCalledWith(true);
      });
    });

    it('shows resolve checkbox', () => {
      expect(
        vm.$el.querySelector('[data-qa-selector="resolve_review_discussion_checkbox"]'),
      ).not.toBe(null);
    });

    it('hides actions for commits', () => {
      vm.discussion.for_commit = true;

      return vm.$nextTick(() => {
        expect(vm.$el.querySelector('.note-form-actions').textContent).not.toContain(
          'Start a review',
        );
      });
    });

    describe('on enter', () => {
      it('should start review or add to review when cmd+enter is pressed', () => {
        jest.spyOn(vm, 'handleAddToReview');
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, true));

        expect(vm.handleAddToReview).toHaveBeenCalled();
      });

      it('should start review or add to review when ctrl+enter is pressed', () => {
        jest.spyOn(vm, 'handleAddToReview');
        vm.$el.querySelector('textarea').value = 'Foo';
        vm.$el.querySelector('textarea').dispatchEvent(keyboardDownEvent(13, false, true));

        expect(vm.handleAddToReview).toHaveBeenCalled();
      });
    });
  });
});
