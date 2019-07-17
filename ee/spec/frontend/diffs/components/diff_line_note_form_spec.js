import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import diffFileMockData from '../mock_data/diff_file';
import note from '../mock_data/note';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('DiffLineNoteForm', () => {
  describe('methods', () => {
    describe('addToReview', () => {
      const state = {
        notes: {
          notesData: { draftsPath: null },
          noteableData: {},
        },
      };
      const getters = {
        getUserData: jest.fn(),
        isLoggedIn: jest.fn(),
        noteableType: jest.fn(),
      };
      const saveDraft = jest.fn();
      const modules = {
        diffs: {
          namespaced: true,
          state: {
            commit: null,
          },
          getters: {
            getDiffFileByHash: jest.fn().mockReturnValue(() => ({
              diff_refs: {
                head_sha: 'abc123',
              },
            })),
          },
        },
        batchComments: {
          namespaced: true,
          actions: {
            saveDraft,
          },
        },
      };
      const getDiffFileMock = () => Object.assign({}, diffFileMockData);
      const diffFile = getDiffFileMock();
      const diffLines = diffFile.highlighted_diff_lines;
      const propsData = {
        diffFileHash: diffFile.file_hash,
        diffLines,
        line: diffLines[0],
        noteTargetLine: diffLines[0],
      };
      it('should call saveDraft action with commit_id === null', () => {
        const store = new Vuex.Store({ state, getters, modules });
        const wrapper = shallowMount(DiffLineNoteForm, {
          store,
          localVue,
          propsData,
        });
        wrapper.vm.addToReview(note);
        const postData = saveDraft.mock.calls[0][1];
        expect(postData.data.note.commit_id).toBe(null);
      });

      it('should call saveDraft action with commit_id !== null', () => {
        modules.diffs.state.commit = 'abc123';
        const store = new Vuex.Store({ state, getters, modules });
        const wrapper = shallowMount(DiffLineNoteForm, {
          store,
          localVue,
          propsData,
        });
        wrapper.vm.addToReview(note);
        const postData = saveDraft.mock.calls[1][1];
        expect(postData.data.note.commit_id).not.toBe(null);
      });
    });
  });
});
