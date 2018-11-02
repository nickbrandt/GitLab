import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import ProjectHeader from 'ee/operations/components/dashboard/project_header.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar/default.vue';
import { removeWhitespace } from 'spec/helpers/vue_component_helper';
import { getChildInstances } from '../../helpers';
import { mockOneProject, mockText } from '../../mock_data';

describe('project header component', () => {
  const ProjectHeaderComponent = Vue.extend(ProjectHeader);
  const ProjectAvatarComponent = Vue.extend(ProjectAvatar);
  let vm;

  beforeEach(() => {
    vm = mountComponentWithStore(ProjectHeaderComponent, {
      props: {
        project: mockOneProject,
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders project name with namespace', () => {
    const name = vm.$el.querySelector('.js-name-with-namespace').innerText;

    expect(removeWhitespace(name).trim()).toBe(mockOneProject.name_with_namespace);
  });

  it('links project name to project', () => {
    const path = mockOneProject.web_url;

    expect(vm.$el.querySelector('.js-project-link').href).toBe(path);
  });

  describe('wrapped components', () => {
    describe('project avatar', () => {
      it('renders', () => {
        expect(getChildInstances(vm, ProjectAvatarComponent).length).toBe(1);
      });

      it('binds project', () => {
        const [avatar] = getChildInstances(vm, ProjectAvatarComponent);

        expect(avatar.project).toEqual(vm.project);
      });
    });
  });

  describe('dropdown menu', () => {
    it('renders removal button', () => {
      expect(vm.$el.querySelector('.js-remove-button').innerText.trim()).toBe(
        mockText.REMOVE_PROJECT,
      );
    });

    it('emits project removal link on click', () => {
      const spy = spyOn(vm, '$emit');
      vm.$el.querySelector('.js-remove-button').click();

      expect(spy).toHaveBeenCalledWith('remove', mockOneProject.remove_path);
    });
  });
});
