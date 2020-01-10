import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlDropdownItem, GlFormInput } from '@gitlab/ui';

const projects = getJSONFixture('static/projects.json');

const GlDropdownStub = {
  name: 'GlDropdown',
  template: '<div><slot></slot></div>',
};

describe('CreateIssueForm', () => {
  let wrapper;

  const createWrapper = () => {
    wrapper = shallowMount(CreateIssueForm, {
      stubs: {
        GlDropdown: GlDropdownStub,
      },
      propsData: {
        projects,
      },
    });
  };

  const findButton = text =>
    wrapper.findAll(GlButton).wrappers.find(button => button.text() === text);

  const findDropdownItems = () => wrapper.findAll(GlDropdownItem);

  const getDropdownToggleText = () => wrapper.find(GlDropdownStub).attributes().text;

  const clickDropdownItem = index =>
    findDropdownItems()
      .at(index)
      .vm.$emit('click');

  it('renders projects dropdown', () => {
    createWrapper();

    expect(findDropdownItems().length).toBeGreaterThan(0);
    expect(findDropdownItems().length).toBe(projects.length);

    const itemTexts = findDropdownItems().wrappers.map(item => item.text());
    itemTexts.forEach((text, index) => {
      const project = projects[index];

      expect(text).toContain(project.name);
      expect(text).toContain(project.namespace.name);
    });
  });

  it('uses selected project as dropdown button text', () => {
    createWrapper();
    expect(getDropdownToggleText()).toBe('Select a project');

    clickDropdownItem(1);

    return wrapper.vm.$nextTick().then(() => {
      expect(getDropdownToggleText()).toBe(projects[1].name_with_namespace);
    });
  });

  describe('cancel button', () => {
    const clickCancel = () => findButton('Cancel').vm.$emit('click');

    it('emits cancel event', () => {
      createWrapper();

      clickCancel();

      expect(wrapper.emitted()).toEqual({ cancel: [[]] });
    });
  });

  describe('submit button', () => {
    const dummyTitle = 'some issue title';

    const clickSubmit = () => findButton('Create issue').vm.$emit('click');
    const fillTitle = title => wrapper.find(GlFormInput).vm.$emit('input', title);

    it('does not emit submit if project is missing', () => {
      createWrapper();
      fillTitle(dummyTitle);

      clickSubmit();

      expect(wrapper.emitted()).toEqual({});
    });

    it('does not emit submit if title is missing', () => {
      createWrapper();
      clickDropdownItem(1);

      clickSubmit();

      expect(wrapper.emitted()).toEqual({});
    });

    it('emits submit event for filled form', () => {
      createWrapper();
      fillTitle(dummyTitle);
      clickDropdownItem(1);

      clickSubmit();

      const issuesEndpoint = projects[1]._links.issues;
      const expectedParams = [{ issuesEndpoint, title: dummyTitle }];
      expect(wrapper.emitted()).toEqual({ submit: [expectedParams] });
    });
  });
});
