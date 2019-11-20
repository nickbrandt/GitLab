import Vue from 'vue';
import component from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import createStore from 'ee/security_dashboard/store';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import mockDataVulnerabilities from '../store/vulnerabilities/data/mock_data_vulnerabilities.json';

describe('Security Dashboard Table Row', () => {
  let vm;
  let props;
  const store = createStore();
  const Component = Vue.extend(component);

  describe('when loading', () => {
    beforeEach(() => {
      props = { isLoading: true };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should display the skeleton loader', () => {
      expect(vm.$el.querySelector('.js-skeleton-loader')).not.toBeNull();
    });

    it('should render a ` ` for severity', () => {
      expect(vm.severity).toEqual(' ');
      expect(vm.$el.querySelectorAll('.table-mobile-content')[0].textContent).toContain(' ');
    });

    it('should render a `–` for confidence', () => {
      expect(vm.confidence).toEqual('–');
      expect(vm.$el.querySelectorAll('.table-mobile-content')[1].textContent).toContain('–');
    });

    it('should not render action buttons', () => {
      expect(vm.$el.querySelectorAll('.action-buttons button').length).toBe(0);
    });
  });

  describe('when loaded', () => {
    const vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      props = { vulnerability };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should not display the skeleton loader', () => {
      expect(vm.$el.querySelector('.js-skeleton-loader')).not.toExist();
    });

    it('should render the severity', () => {
      expect(
        vm.$el.querySelectorAll('.table-mobile-content')[0].textContent.toLowerCase(),
      ).toContain(props.vulnerability.severity);
    });

    it('should render the confidence', () => {
      expect(
        vm.$el.querySelectorAll('.table-mobile-content')[1].textContent.toLowerCase(),
      ).toContain(props.vulnerability.confidence);
    });

    describe('the project name', () => {
      it('should render the name', () => {
        expect(vm.$el.querySelectorAll('.table-mobile-content')[2].textContent).toContain(
          props.vulnerability.name,
        );
      });

      it('should render the project namespace', () => {
        expect(vm.$el.querySelectorAll('.table-mobile-content')[2].textContent).toContain(
          props.vulnerability.project.full_name,
        );
      });

      it('should fire the openModal action when clicked', () => {
        spyOn(vm.$store, 'dispatch');

        vm.$el.querySelector('.vulnerability-title').click();

        expect(vm.$store.dispatch).toHaveBeenCalledWith('vulnerabilities/openModal', {
          vulnerability,
        });
      });
    });
  });

  describe('with a dismissed vulnerability', () => {
    const vulnerability = mockDataVulnerabilities[2];

    beforeEach(() => {
      props = { vulnerability };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should have a `dismissed` class', () => {
      expect(vm.$el.classList).toContain('dismissed');
    });

    it('should render a `DISMISSED` tag', () => {
      expect(vm.$el.textContent).toContain('dismissed');
    });
  });

  describe('with valid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[3];

    beforeEach(() => {
      props = { vulnerability };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should have a `ic-issue-created` class', () => {
      expect(vm.$el.querySelectorAll('.ic-issue-created')).toHaveLength(1);
    });
  });

  describe('with invalid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[6];

    beforeEach(() => {
      props = { vulnerability };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should not have a `ic-issue-created` class', () => {
      expect(vm.$el.querySelectorAll('.ic-issue-created')).toHaveLength(0);
    });
  });

  describe('with no issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      props = { vulnerability };
      vm = mountComponentWithStore(Component, { store, props });
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should not have a `ic-issue-created` class', () => {
      expect(vm.$el.querySelectorAll('.ic-issue-created')).toHaveLength(0);
    });
  });
});
