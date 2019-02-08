import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import createState from 'ee/vue_shared/security_reports/store/state';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/vue_component_helper';
import { TEST_HOST } from 'spec/test_constants';

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
          canCreateFeedbackPermission: true,
        };
        props.modal.vulnerability.isDismissed = true;
        props.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith' },
          pipeline: { id: '123' },
        };
        vm = mountComponent(Component, props);
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(vm.$el.textContent.trim()).toContain('@jsmith');
        expect(vm.$el.textContent.trim()).toContain('#123');
      });

      it('renders button to undo dismiss', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual('Undo dismiss');
      });

      it('emits revertDismissIssue when undo dismiss button is clicked', () => {
        spyOn(vm, '$emit');

        const button = vm.$el.querySelector('.js-dismiss-btn');
        button.click();

        expect(vm.$emit).toHaveBeenCalledWith('revertDismissIssue');
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canCreateFeedbackPermission: true,
        };
        vm = mountComponent(Component, props);
      });

      it('renders button to dismiss issue', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual(
          'Dismiss vulnerability',
        );
      });

      it('does not render create issue button', () => {
        expect(vm.$el.querySelector('.js-create-issue-btn')).toBe(null);
      });

      it('renders create issue button and footer', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn')).not.toBe(null);
      });

      it('renders the footer', () => {
        expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
      });

      it('emits dismissIssue when dismiss issue button is clicked', () => {
        spyOn(vm, '$emit');

        const button = vm.$el.querySelector('.js-dismiss-btn');
        button.click();

        expect(vm.$emit).toHaveBeenCalledWith('dismissIssue');
      });
    });

    describe('with create issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canCreateIssuePermission: true,
        };
        vm = mountComponent(Component, props);
      });

      it('does not render dismiss button', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn')).toBe(null);
      });

      it('renders create issue button', () => {
        expect(vm.$el.querySelector('.js-create-issue-btn')).not.toBe(null);
      });

      it('renders the footer', () => {
        expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
      });

      it('emits createIssue when create issue button is clicked', () => {
        spyOn(vm, '$emit');

        const button = vm.$el.querySelector('.js-create-issue-btn');
        button.click();

        expect(vm.$emit).toHaveBeenCalledWith('createNewIssue');
      });
    });

    describe('with instances', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
        };
        props.modal.data.instances.value = [
          { uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc' },
          { uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md' },
        ];
        vm = mountComponent(Component, props);
      });

      it('renders instances list', () => {
        const instances = vm.$el.querySelectorAll('.report-block-list li');

        expect(instances[0].textContent).toContain(
          'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        );

        expect(instances[1].textContent).toContain(
          'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        );
      });
    });

    describe('data', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          vulnerabilityFeedbackHelpPath: 'feedbacksHelpPath',
        };
        props.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        props.modal.data.file.value = 'Gemfile.lock';
        props.modal.data.file.url = `${TEST_HOST}/path/Gemfile.lock`;
        vm = mountComponent(Component, props);
      });

      it('renders keys in `data`', () => {
        expect(vm.$el.textContent).toContain('Arbitrary file existence disclosure in Action Pack');
      });

      it('renders link fields with link', () => {
        expect(vm.$el.querySelector('.js-link-file').getAttribute('href')).toEqual(
          `${TEST_HOST}/path/Gemfile.lock`,
        );
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

    it('does not render action buttons', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn')).toBe(null);
      expect(vm.$el.querySelector('.js-create-issue-btn')).toBe(null);
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
      props.modal.vulnerability.remediation = { summary };
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

  describe('does not render XSS links', () => {
    // eslint-disable-next-line no-script-url
    const badUrl = 'javascript:alert("")';

    beforeEach(() => {
      const props = {
        modal: createState().modal,
      };

      props.modal.data.file.value = 'badFile.lock';
      props.modal.data.file.url = badUrl;
      props.modal.data.links.value = [
        {
          url: badUrl,
        },
      ];
      props.modal.data.identifiers.value = [
        {
          type: 'CVE',
          name: 'BAD_URL',
          url: badUrl,
        },
      ];
      props.modal.data.instances.value = [
        {
          param: 'X-Content-Type-Options',
          method: 'GET',
          uri: badUrl,
        },
      ];

      vm = mountComponent(Component, props);
    });

    it('for the link field', () => {
      const linkEl = vm.$el.querySelector('.js-link-links');

      expect(linkEl.tagName).not.toBe('A');
      expect(trimText(linkEl.textContent)).toBe(badUrl);
    });

    it('for the identifiers field', () => {
      const linkEl = vm.$el.querySelector('.js-link-identifiers');

      expect(linkEl.tagName).not.toBe('A');
      expect(trimText(linkEl.textContent)).toBe('BAD_URL');
    });

    it('for the file field', () => {
      const linkEl = vm.$el.querySelector('.js-link-file');

      expect(linkEl.tagName).not.toBe('A');
      expect(trimText(linkEl.textContent)).toBe('badFile.lock');
    });

    it('for the instances field', () => {
      const linkEl = vm.$el.querySelector('.report-block-list-issue-description-link .break-link');

      expect(linkEl.tagName).not.toBe('A');
      expect(trimText(linkEl.textContent)).toBe(badUrl);
    });
  });
});
