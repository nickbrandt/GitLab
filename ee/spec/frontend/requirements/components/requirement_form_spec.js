import { shallowMount } from '@vue/test-utils';

import { GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import RequirementForm from 'ee/requirements/components/requirement_form.vue';
import { MAX_TITLE_LENGTH } from 'ee/requirements/constants';

import { mockRequirementsOpen } from '../mock_data';

const createComponent = ({ requirement = null, requirementRequestActive = false } = {}) =>
  shallowMount(RequirementForm, {
    propsData: {
      requirement,
      requirementRequestActive,
    },
  });

describe('RequirementForm', () => {
  let wrapper;
  let wrapperWithRequirement;

  beforeEach(() => {
    wrapper = createComponent();
    wrapperWithRequirement = createComponent({
      requirement: mockRequirementsOpen[0],
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapperWithRequirement.destroy();
  });

  describe('computed', () => {
    describe('fieldLabel', () => {
      it('returns string "New requirement" when `requirement` prop is null', () => {
        expect(wrapper.vm.fieldLabel).toBe('New requirement');
      });

      it('returns string "Requirement" when `requirement` prop is defined', () => {
        expect(wrapperWithRequirement.vm.fieldLabel).toBe('Requirement');
      });
    });

    describe('saveButtonLabel', () => {
      it('returns string "Create requirement" when `requirement` prop is null', () => {
        expect(wrapper.vm.saveButtonLabel).toBe('Create requirement');
      });

      it('returns string "Save changes" when `requirement` prop is defined', () => {
        expect(wrapperWithRequirement.vm.saveButtonLabel).toBe('Save changes');
      });
    });

    describe('titleInvalid', () => {
      it('returns `false` when `title` length is less than max title limit', () => {
        expect(wrapper.vm.titleInvalid).toBe(false);
      });

      it('returns `true` when `title` length is more than max title limit', () => {
        wrapper.setData({
          title: Array(MAX_TITLE_LENGTH + 1)
            .fill()
            .map(() => 'a')
            .join(''),
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.titleInvalid).toBe(true);
        });
      });
    });

    describe('reference', () => {
      it('returns string containing `requirement.iid` prefixed with `REQ-`', () => {
        expect(wrapperWithRequirement.vm.reference).toBe(`REQ-${mockRequirementsOpen[0].iid}`);
      });
    });
  });

  describe('methods', () => {
    describe('handleSave', () => {
      it('emits `save` event on component with `title` as param when form is in create mode', () => {
        wrapper.setData({
          title: 'foo',
        });

        wrapper.vm.handleSave();

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.emitted('save')).toBeTruthy();
          expect(wrapper.emitted('save')[0]).toEqual(['foo']);
        });
      });

      it('emits `save` event on component with object as param containing `iid` & `title` when form is in update mode', () => {
        wrapperWithRequirement.vm.handleSave();

        return wrapperWithRequirement.vm.$nextTick(() => {
          expect(wrapperWithRequirement.emitted('save')).toBeTruthy();
          expect(wrapperWithRequirement.emitted('save')[0]).toEqual([
            {
              iid: mockRequirementsOpen[0].iid,
              title: mockRequirementsOpen[0].title,
            },
          ]);
        });
      });
    });
  });

  describe('template', () => {
    it('renders component container element with classes `p-3 border-bottom` when form is in create mode', () => {
      const wrapperClasses = wrapper.classes();

      expect(wrapperClasses).toContain('p-3');
      expect(wrapperClasses).toContain('border-bottom');
    });

    it('renders component container element with classes `d-block d-sm-flex` when form is in edit mode', () => {
      const wrapperClasses = wrapperWithRequirement.classes();

      expect(wrapperClasses).toContain('d-block');
      expect(wrapperClasses).toContain('d-sm-flex');
    });

    it('renders element containing requirement reference when form is in edit mode', () => {
      expect(wrapperWithRequirement.find('span').text()).toBe(`REQ-${mockRequirementsOpen[0].iid}`);
    });

    it('renders gl-form-group component', () => {
      const glFormGroup = wrapper.find(GlFormGroup);

      expect(glFormGroup.exists()).toBe(true);
      expect(glFormGroup.attributes('label')).toBe('New requirement');
      expect(glFormGroup.attributes('label-for')).toBe('requirementTitle');
      expect(glFormGroup.attributes('invalid-feedback')).toBe(
        `Requirement title cannot have more than ${MAX_TITLE_LENGTH} characters.`,
      );
      expect(glFormGroup.attributes('state')).toBe('true');
    });

    it('renders gl-form-textarea component', () => {
      const glFormTextarea = wrapper.find(GlFormTextarea);

      expect(glFormTextarea.exists()).toBe(true);
      expect(glFormTextarea.attributes('id')).toBe('requirementTitle');
      expect(glFormTextarea.attributes('placeholder')).toBe('Describe the requirement here');
      expect(glFormTextarea.attributes('max-rows')).toBe('25');
    });

    it('renders gl-form-textarea component populated with `requirement.title` when `requirement` prop is defined', () => {
      expect(wrapperWithRequirement.find(GlFormTextarea).attributes('value')).toBe(
        mockRequirementsOpen[0].title,
      );
    });

    it('renders save button component', () => {
      const saveButton = wrapper.find('.js-requirement-save');

      expect(saveButton.exists()).toBe(true);
      expect(saveButton.text()).toBe('Create requirement');
    });

    it('renders cancel button component', () => {
      const cancelButton = wrapper.find('.js-requirement-cancel');

      expect(cancelButton.exists()).toBe(true);
      expect(cancelButton.text()).toBe('Cancel');
    });
  });
});
