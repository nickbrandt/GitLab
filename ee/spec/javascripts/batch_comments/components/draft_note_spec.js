import Vue from 'vue';
import DraftNote from 'ee/batch_comments/components/draft_note.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

describe('Batch comments draft note component', () => {
  let vm;
  let Component;
  let draft;

  beforeAll(() => {
    Component = Vue.extend(DraftNote);
  });

  beforeEach(() => {
    const store = createStore();

    draft = createDraft();

    vm = mountComponentWithStore(Component, { store, props: { draft } });

    spyOn(vm.$store, 'dispatch').and.stub();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders template', () => {
    expect(vm.$el.querySelector('.draft-pending-label')).not.toBe(null);
    expect(vm.$el.querySelector('.draft-notes').textContent).toContain('Test');
  });

  describe('in discussion', () => {
    beforeEach(done => {
      vm.draft.discussion_id = '123';

      vm.$nextTick(done);
    });

    it('renders resolution status', () => {
      expect(vm.$el.querySelector('.line-resolve-btn')).not.toBe(null);
    });
  });

  describe('add comment now', () => {
    it('dispatches publishSingleDraft when clicking', () => {
      vm.$el.querySelectorAll('.btn-inverted')[1].click();

      expect(vm.$store.dispatch).toHaveBeenCalledWith('batchComments/publishSingleDraft', 1);
    });

    it('sets as loading when draft is publishing', done => {
      vm.$store.state.batchComments.currentlyPublishingDrafts.push(1);

      vm.$nextTick(() => {
        expect(vm.$el.querySelectorAll('.btn-inverted')[1].getAttribute('disabled')).toBe(
          'disabled',
        );

        done();
      });
    });
  });

  describe('update', () => {
    it('dispatches updateDraft', done => {
      vm.$el.querySelector('.js-note-edit').click();

      vm.$nextTick()
        .then(() => {
          vm.$el.querySelector('.js-vue-issue-save').click();

          expect(vm.$store.dispatch).toHaveBeenCalledWith('batchComments/updateDraft', {
            note: draft,
            noteText: 'a',
            resolveDiscussion: false,
            callback: jasmine.any(Function),
          });
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('deleteDraft', () => {
    it('dispatches deleteDraft', () => {
      spyOn(window, 'confirm').and.callFake(() => true);

      vm.$el.querySelector('.js-note-delete').click();

      expect(vm.$store.dispatch).toHaveBeenCalledWith('batchComments/deleteDraft', draft);
    });
  });

  describe('quick actions', () => {
    it('renders referenced commands', done => {
      vm.draft.references.commands = 'test command';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.referenced-commands')).not.toBe(null);
        expect(vm.$el.querySelector('.referenced-commands').textContent).toContain('test command');

        done();
      });
    });
  });
});
