import Vue from 'vue';
import { mount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import IssueSystemNote from '~/vue_shared/components/notes/system_note.vue';
import createStore from '~/notes/stores';
import initMRPopovers from '~/mr_popover/index';

jest.mock('~/mr_popover/index', () => jest.fn());

describe('system note component', () => {
  let vm;
  let props;
  let mock;

  beforeEach(() => {
    props = {
      note: {
        id: '1424',
        author: {
          id: 1,
          name: 'Root',
          username: 'root',
          state: 'active',
          avatar_url: 'path',
          path: '/root',
        },
        note_html: '<p dir="auto">closed</p>',
        system_note_icon_name: 'status_closed',
        created_at: '2017-08-02T10:51:58.559Z',
        description_version_id: 1,
        description_diff_path: 'path/to/diff',
        delete_description_version_path: 'path/to/diff/1',
        can_delete_description_version: true,
        description_version_deleted: false,
      },
    };

    const store = createStore();
    store.dispatch('setTargetNoteHash', `note_${props.note.id}`);

    mock = new MockAdapter(axios);

    vm = mount(IssueSystemNote, {
      store,
      propsData: props,
      provide: {
        glFeatures: { saveDescriptionVersions: true, descriptionDiffs: true },
      },
    });
  });

  afterEach(() => {
    mock.restore();
    vm.destroy();
  });

  it('should render a list item with correct id', () => {
    expect(vm.attributes('id')).toEqual(`note_${props.note.id}`);
  });

  it('should render target class is note is target note', () => {
    expect(vm.classes()).toContain('target');
  });

  it('should render svg icon', () => {
    expect(vm.find('.timeline-icon svg').exists()).toBe(true);
  });

  // Redcarpet Markdown renderer wraps text in `<p>` tags
  // we need to strip them because they break layout of commit lists in system notes:
  // https://gitlab.com/gitlab-org/gitlab-foss/uploads/b07a10670919254f0220d3ff5c1aa110/jqzI.png
  it('removes wrapping paragraph from note HTML', () => {
    expect(vm.find('.system-note-message').html()).toContain('<span>closed</span>');
  });

  it('should initMRPopovers onMount', () => {
    expect(initMRPopovers).toHaveBeenCalled();
  });

  it('should display button to toggle description diff, description version does not display', () => {
    const button = vm.find('.note-headline-light .btn-blank');
    expect(button).toExist();
    expect(button.text()).toContain('Compare with previous version');
    expect(vm.find('.description-version').exists()).toBe(false);
  });

  it('click on button to toggle description diff displays description diff with delete icon button', done => {
    const diffData =
      '<span class="idiff">Description</span><span class="idiff addition">Diff</span>';
    mock.onGet(`/path/to/diff/1`).replyOnce(200, {
      data: diffData,
    });

    const button = vm.find('.note-headline-light .btn-blank');
    button.trigger('click');
    Vue.nextTick(() => {
      expect(vm.find('.description-version').exists()).toBe(true);
      expect(vm.find('.description-version').html()).toContain(diffData);
      expect(
        vm.find('.description-version button.delete-description-history svg.s16').exists(),
      ).toBe(true);

      done();
    });
  });

  it('click on delete icon button deletes description diff', done => {
    vm.find('.note-headline-light .btn-blank').trigger('click');
    Vue.nextTick(() => {
      const button = vm.find('.description-version button.delete-description-history');
      button.trigger('click');
      expect(vm.find('.description-version').text()).toContain('Deleted');

      done();
    });
  });
});
