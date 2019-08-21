import { shallowMount } from '@vue/test-utils';

import DesignReplyForm from 'ee/design_management/components/design_notes/design_reply_form.vue';

describe('Design reply form component', () => {
  let wrapper;

  const findTextarea = () => wrapper.find('textarea');
  const findSubmitButton = () => wrapper.find('.js-comment-submit-button');

  function createComponent(props = {}) {
    wrapper = shallowMount(DesignReplyForm, {
      sync: false,
      propsData: {
        value: '',
        isSaving: false,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('textarea has focus after component mount', () => {
    createComponent();

    expect(findTextarea().element).toEqual(document.activeElement);
  });

  describe('when form has no text', () => {
    beforeEach(() => {
      createComponent({
        value: '',
      });
    });

    it('submit button is disabled', () => {
      expect(findSubmitButton().attributes().disabled).toBeTruthy();
    });

    it('does not emit submitForm event on textarea ctrl+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      expect(wrapper.emitted('submitForm')).toBeFalsy();
    });

    it('does not emit submitForm event on textarea meta+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      expect(wrapper.emitted('submitForm')).toBeFalsy();
    });
  });

  describe('when form has text', () => {
    beforeEach(() => {
      createComponent({
        value: 'test',
      });
    });

    it('submit button is enabled', () => {
      expect(findSubmitButton().attributes().disabled).toBeFalsy();
    });

    it('emits submitForm event on button click', () => {
      findSubmitButton().trigger('click');

      expect(wrapper.emitted('submitForm')).toBeTruthy();
    });

    it('emits submitForm event on textarea ctrl+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        ctrlKey: true,
      });

      expect(wrapper.emitted('submitForm')).toBeTruthy();
    });

    it('emits submitForm event on textarea meta+enter keydown', () => {
      findTextarea().trigger('keydown.enter', {
        metaKey: true,
      });

      expect(wrapper.emitted('submitForm')).toBeTruthy();
    });

    it('emits input event on changing textarea content', () => {
      findTextarea().setValue('test2');

      expect(wrapper.emitted('input')).toBeTruthy();
    });

    it('emits cancelForm event on pressing escape button on textarea', () => {
      findTextarea().trigger('keyup.esc');

      expect(wrapper.emitted('cancelForm')).toBeTruthy();
    });
  });
});
