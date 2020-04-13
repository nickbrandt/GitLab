import { shallowMount } from '@vue/test-utils';
import { GlFormTextarea } from '@gitlab/ui';
import HistoryCommentEditor from 'ee/vulnerabilities/components/history_comment_editor.vue';

describe('History Comment Editor', () => {
  let wrapper;

  const createWrapper = props => {
    wrapper = shallowMount(HistoryCommentEditor, {
      propsData: { isSaving: false, ...props },
    });
  };

  const textarea = () => wrapper.find(GlFormTextarea);
  const saveButton = () => wrapper.find({ ref: 'saveButton' });
  const cancelButton = () => wrapper.find({ ref: 'cancelButton' });

  afterEach(() => wrapper.destroy());

  it('shows the placeholder text when there is no comment', () => {
    createWrapper();
    expect(textarea().props('value')).toBeFalsy();
  });

  it('shows the comment when one is passed in', () => {
    const initialComment = 'some comment';
    createWrapper({ initialComment });
    expect(textarea().props('value')).toBe(initialComment);
  });

  it('trims the comment when there are extra spaces', () => {
    const initialComment = '    some comment    ';
    createWrapper({ initialComment });
    expect(textarea().props('value')).toBe(initialComment.trim());
  });

  it('emits the save event with the new comment when the save button is clicked', () => {
    createWrapper();
    const comment = 'new comment';
    textarea().vm.$emit('input', comment);
    saveButton().vm.$emit('click');

    expect(wrapper.emitted().onSave.length).toBe(1);
    expect(wrapper.emitted().onSave[0][0]).toBe(comment);
  });

  it('emits the cancel event when the cancel button is clicked', () => {
    createWrapper();
    cancelButton().vm.$emit('click');

    expect(wrapper.emitted().onCancel.length).toBe(1);
  });

  it('disables the save button when there is no text or only whitespace in the textarea', () => {
    createWrapper({ initialComment: 'some comment' });
    textarea().vm.$emit('input', '    ');

    return wrapper.vm.$nextTick().then(() => {
      expect(saveButton().attributes('disabled')).toBeTruthy();
    });
  });

  it('disables all elements when the isSaving prop is true', () => {
    createWrapper({ isSaving: true });

    expect(textarea().attributes('disabled')).toBeTruthy();
    expect(saveButton().attributes('disabled')).toBeTruthy();
    expect(cancelButton().attributes('disabled')).toBeTruthy();
  });
});
