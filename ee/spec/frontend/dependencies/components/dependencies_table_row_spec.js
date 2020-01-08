import { createLocalVue, shallowMount } from '@vue/test-utils';
import DependenciesTableRow from 'ee/dependencies/components/dependencies_table_row.vue';
import DependencyVulnerability from 'ee/dependencies/components/dependency_vulnerability.vue';
import { MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY } from 'ee/dependencies/components/constants';
import { makeDependency } from './utils';
import mockDataVulnerabilities from '../../../javascripts/security_dashboard/store/vulnerabilities/data/mock_data_vulnerabilities.json';

describe('DependenciesTableRow component', () => {
  let wrapper;

  const factory = ({ propsData, ...options } = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(DependenciesTableRow, {
      ...options,
      localVue,
      sync: false,
      propsData: { ...propsData },
    });
  };

  const findVulnerabilities = () => wrapper.findAll(DependencyVulnerability).wrappers;
  const findExcessMessage = () => wrapper.find('.js-excess-message');
  const expectVulnerabilitiesCollapsed = () => expect(findVulnerabilities()).toHaveLength(0);

  const expectVulnerabilitiesExpanded = vulnerabilities => {
    const wrappers = findVulnerabilities();
    expect(wrappers).toHaveLength(vulnerabilities.length);
    wrappers.forEach((vulnerabilityWrapper, i) => {
      expect(vulnerabilityWrapper.isVisible()).toBe(true);
      expect(vulnerabilityWrapper.props().vulnerability).toEqual(vulnerabilities[i]);
    });
    expect(findExcessMessage().exists()).toBe(false);
  };

  const clickToggle = () => {
    wrapper.find('.js-vulnerabilities-toggle').vm.$emit('click');
    return wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when passed no props', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      factory({
        propsData: {
          isLoading: true,
        },
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when a dependency with no vulnerabilities is loaded', () => {
    beforeEach(() => {
      factory({
        propsData: {
          isLoading: false,
          dependency: makeDependency({ vulnerabilities: [] }),
        },
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when a dependency with vulnerabilities is loaded', () => {
    beforeEach(() => {
      factory({
        propsData: {
          isLoading: false,
          dependency: makeDependency({ vulnerabilities: mockDataVulnerabilities }),
        },
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('when the list of vulnerabilities is expanded', () => {
      beforeEach(clickToggle);

      it('renders each vulnerability', () => {
        expectVulnerabilitiesExpanded(mockDataVulnerabilities);
      });

      describe('when clicking the toggle ', () => {
        beforeEach(clickToggle);

        it('closes the list of vulnerabilities', expectVulnerabilitiesCollapsed);
      });

      describe('when the dependency prop changes', () => {
        beforeEach(() => {
          wrapper.setProps({
            dependency: makeDependency({ vulnerabilities: mockDataVulnerabilities }),
          });

          return wrapper.vm.$nextTick();
        });

        it('closes the list of vulnerabilities', expectVulnerabilitiesCollapsed);
      });

      describe('when the isLoading prop changes', () => {
        beforeEach(() => {
          wrapper.setProps({
            isLoading: true,
          });

          return wrapper.vm.$nextTick();
        });

        it('closes the list of vulnerabilities', expectVulnerabilitiesCollapsed);
      });
    });
  });

  describe('when a dependency with a huge number vulnerabilities is loaded and expanded', () => {
    beforeEach(() => {
      const hugeNumberOfVulnerabilities = Array(1 + MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY)
        .fill(null)
        .map((_, id) => ({ id }));

      factory({
        propsData: {
          isLoading: false,
          dependency: makeDependency({ vulnerabilities: hugeNumberOfVulnerabilities }),
        },
      });

      return clickToggle();
    });

    it('does not render all of them', () => {
      expect(findVulnerabilities().length).toBe(MAX_DISPLAYED_VULNERABILITIES_PER_DEPENDENCY);
      expect(findExcessMessage().isVisible()).toBe(true);
    });
  });
});
