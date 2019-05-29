import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import createState from 'ee/vue_shared/security_reports/store/state';
import mountComponent from 'helpers/vue_mount_component_helper';

describe('Security Reports modal', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with permissions', () => {
    describe('with dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        props.modal.vulnerability.isDismissed = true;
        props.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith', name: 'John Smith' },
          pipeline: { id: '123', path: '#' },
        };
        vm = mountComponent(Component, props);
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(vm.$el.textContent.trim()).toContain('John Smith');
        expect(vm.$el.textContent.trim()).toContain('@jsmith');
        expect(vm.$el.textContent.trim()).toContain('#123');
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canDismissVulnerability: true,
        };
        vm = mountComponent(Component, props);
      });

      it('renders the footer', () => {
        expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
      });
    });

    describe('data', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          vulnerabilityFeedbackHelpPath: 'feedbacksHelpPath',
        };
        props.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        vm = mountComponent(Component, props);
      });

      it('renders title', () => {
        expect(vm.$el.textContent).toContain('Arbitrary file existence disclosure in Action Pack');
      });

      it('renders help link', () => {
        expect(
          vm.$el.querySelector('.js-link-vulnerabilityFeedbackHelpPath').getAttribute('href'),
        ).toEqual('feedbacksHelpPath');
      });
    });
  });

  describe('without permissions', () => {
    beforeEach(() => {
      const props = {
        modal: createState().modal,
      };
      vm = mountComponent(Component, props);
    });

    it('does not display the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(true);
    });
  });

  describe('with a resolved issue', () => {
    beforeEach(() => {
      const props = {
        modal: createState().modal,
      };
      props.modal.isResolved = true;
      vm = mountComponent(Component, props);
    });

    it('does not display the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toBeTruthy();
    });
  });

  describe('Vulnerability Details', () => {
    const blobPath = '/group/project/blob/1ab2c3d4e5/some/file.path#L0-0';
    const namespaceValue = 'foobar';
    const fileValue = '/some/file.path';

    beforeEach(() => {
      const props = {
        modal: createState().modal,
      };
      props.modal.vulnerability.blob_path = blobPath;
      props.modal.data.namespace.value = namespaceValue;
      props.modal.data.file.value = fileValue;
      vm = mountComponent(Component, props);
    });

    it('is rendered', () => {
      const vulnerabilityDetails = vm.$el.querySelector('.js-vulnerability-details');

      expect(vulnerabilityDetails).not.toBeNull();
      expect(vulnerabilityDetails.textContent).toContain('foobar');
    });

    it('computes valued fields properly', () => {
      expect(vm.valuedFields).toMatchObject({
        file: {
          value: fileValue,
          url: blobPath,
          isLink: true,
          text: 'File',
        },
        namespace: {
          value: namespaceValue,
          text: 'Namespace',
          isLink: false,
        },
      });
    });
  });

  describe('Solution Card', () => {
    it('is rendered if the vulnerability has a solution', () => {
      const props = {
        modal: createState().modal,
      };

      const solution = 'Upgrade to XYZ';
      props.modal.vulnerability.solution = solution;
      vm = mountComponent(Component, props);

      const solutionCard = vm.$el.querySelector('.js-solution-card');

      expect(solutionCard).not.toBeNull();
      expect(solutionCard.textContent).toContain(solution);
      expect(vm.$el.querySelector('hr')).toBeNull();
    });

    it('is rendered if the vulnerability has a remediation', () => {
      const props = {
        modal: createState().modal,
      };
      const summary = 'Upgrade to 123';
      props.modal.vulnerability.remediations = [{ summary }];
      vm = mountComponent(Component, props);

      const solutionCard = vm.$el.querySelector('.js-solution-card');

      expect(solutionCard).not.toBeNull();
      expect(solutionCard.textContent).toContain(summary);
      expect(vm.$el.querySelector('hr')).toBeNull();
    });

    it('is not rendered if the vulnerability has neither a remediation nor a solution but renders a HR instead.', () => {
      const props = {
        modal: createState().modal,
      };
      vm = mountComponent(Component, props);

      const solutionCard = vm.$el.querySelector('.js-solution-card');

      expect(solutionCard).toBeNull();
      expect(vm.$el.querySelector('hr')).not.toBeNull();
    });
  });
});
