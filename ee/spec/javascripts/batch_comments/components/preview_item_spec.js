import Vue from 'vue';
import PreviewItem from 'ee/batch_comments/components/preview_item.vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/mr_notes/stores';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

describe('Batch comments draft preview item component', () => {
  let vm;
  let Component;
  let draft;

  function createComponent(isLast = false, extra = {}, extendStore = () => {}) {
    const store = createStore();

    extendStore(store);

    draft = {
      ...createDraft(),
      ...extra,
    };

    vm = mountComponentWithStore(Component, { store, props: { draft, isLast } });
  }

  beforeAll(() => {
    Component = Vue.extend(PreviewItem);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders text content', () => {
    createComponent(false, { note_html: '<img src="" /><p>Hello world</p>' });

    expect(vm.$el.querySelector('.review-preview-item-content').innerHTML).toEqual(
      '<p>Hello world</p>',
    );
  });

  it('adds is last class', () => {
    createComponent(true);

    expect(vm.$el.classList).toContain('is-last');
  });

  it('scrolls to draft on click', () => {
    createComponent();

    spyOn(vm.$store, 'dispatch').and.stub();

    vm.$el.click();

    expect(vm.$store.dispatch).toHaveBeenCalledWith('batchComments/scrollToDraft', vm.draft);
  });

  describe('for file', () => {
    it('renders file path', () => {
      createComponent(false, { file_path: 'index.js', file_hash: 'abc', position: {} });

      expect(vm.$el.querySelector('.review-preview-item-header-text').textContent).toContain(
        'index.js',
      );
    });

    it('renders new line position', () => {
      createComponent(false, {
        file_path: 'index.js',
        file_hash: 'abc',
        position: { new_line: 1 },
      });

      expect(vm.$el.querySelector('.bold').textContent).toContain(':1');
    });

    it('renders old line position', () => {
      createComponent(false, {
        file_path: 'index.js',
        file_hash: 'abc',
        position: { old_line: 2 },
      });

      expect(vm.$el.querySelector('.bold').textContent).toContain(':2');
    });
  });

  describe('for discussion', () => {
    beforeEach(() => {
      createComponent(false, { discussion_id: '1', resolve_discussion: true }, store => {
        store.state.notes.discussions.push({
          id: '1',
          notes: [
            {
              author: {
                name: 'Author Name',
              },
            },
          ],
        });
      });
    });

    it('renders title', () => {
      expect(vm.$el.querySelector('.review-preview-item-header-text').textContent).toContain(
        "Author Name's discussion",
      );
    });

    it('it renders discussion resolved text', () => {
      expect(vm.$el.querySelector('.draft-note-resolution').textContent).toContain(
        'Discussion will be resolved',
      );
    });
  });
});
