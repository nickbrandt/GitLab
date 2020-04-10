import { nextTick } from 'vue';
import { mount, shallowMount } from '@vue/test-utils';
import { GlBadge, GlButton, GlLink, GlSkeletonLoading } from '@gitlab/ui';
import DependenciesTable from 'ee/dependencies/components/dependencies_table.vue';
import DependenciesTableRow from 'ee/dependencies/components/dependencies_table_row.vue';
import DependencyLicenseLinks from 'ee/dependencies/components/dependency_license_links.vue';
import DependencyVulnerabilities from 'ee/dependencies/components/dependency_vulnerabilities.vue';
import { makeDependency } from './utils';

describe('DependenciesTable component', () => {
  let wrapper;

  const factory = ({ propsData, ...options } = {}) => {
    wrapper = shallowMount(DependenciesTable, {
      ...options,
      propsData: { ...propsData },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given an empty list of dependencies', () => {
    beforeEach(() => {
      factory({
        propsData: {
          dependencies: [],
          isLoading: false,
        },
      });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  [true, false].forEach(isLoading => {
    describe(`given a list of dependencies (${isLoading ? 'loading' : 'loaded'})`, () => {
      let dependencies;
      beforeEach(() => {
        dependencies = [makeDependency(), makeDependency({ name: 'foo' })];
        factory({
          propsData: {
            dependencies,
            isLoading,
          },
        });
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('passes the correct props to the table rows', () => {
        const rows = wrapper.findAll(DependenciesTableRow).wrappers;
        rows.forEach((row, index) => {
          expect(row.props()).toEqual(
            expect.objectContaining({
              dependency: dependencies[index],
              isLoading,
            }),
          );
        });
      });
    });
  });

  describe('given the dependencyListUi feature flag is enabled', () => {
    const createComponent = ({ propsData, ...options } = {}) => {
      const stubs = Object.keys(DependenciesTable.components).filter(
        component => component !== 'GlTable',
      );

      wrapper = mount(DependenciesTable, {
        ...options,
        propsData: { ...propsData },
        provide: { glFeatures: { dependencyListUi: true } },
        stubs,
      });
    };

    const findTableRows = () => wrapper.findAll('tbody > tr');
    const findRowToggleButtons = () => wrapper.findAll(GlButton);
    const findDependencyVulnerabilities = () => wrapper.find(DependencyVulnerabilities);
    const normalizeWhitespace = string => string.replace(/\s+/g, ' ');

    const expectDependencyRow = (rowWrapper, dependency) => {
      const [
        componentCell,
        packagerCell,
        locationCell,
        licenseCell,
        isVulnerableCell,
      ] = rowWrapper.findAll('td').wrappers;

      expect(normalizeWhitespace(componentCell.text())).toBe(
        `${dependency.name} ${dependency.version}`,
      );

      expect(packagerCell.text()).toBe(dependency.packager);

      const locationLink = locationCell.find(GlLink);
      expect(locationLink.attributes().href).toBe(dependency.location.blob_path);
      expect(locationLink.text()).toBe(dependency.location.path);

      const licenseLinks = licenseCell.find(DependencyLicenseLinks);
      expect(licenseLinks.exists()).toBe(true);
      expect(licenseLinks.props()).toEqual({
        licenses: dependency.licenses,
        title: dependency.name,
      });

      const isVulnerableCellText = normalizeWhitespace(isVulnerableCell.text());
      if (dependency.vulnerabilities.length) {
        expect(isVulnerableCellText).toContain(`${dependency.vulnerabilities.length} vuln`);
      } else {
        expect(isVulnerableCellText).toBe('');
      }
    };

    describe('given the table is loading', () => {
      let dependencies;

      beforeEach(() => {
        dependencies = [makeDependency()];
        createComponent({
          propsData: {
            dependencies,
            isLoading: true,
          },
        });
      });

      it('renders the loading skeleton', () => {
        expect(wrapper.contains(GlSkeletonLoading)).toBe(true);
      });

      it('does not render any dependencies', () => {
        expect(wrapper.text()).not.toContain(dependencies[0].name);
      });
    });

    describe('given an empty list of dependencies', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            dependencies: [],
            isLoading: false,
          },
        });
      });

      it('renders the table header', () => {
        const expectedLabels = DependenciesTable.fields.map(({ label }) => label);
        const headerCells = wrapper.findAll('thead th').wrappers;

        expect(headerCells.map(cell => cell.text())).toEqual(expectedLabels);
      });

      it('does not render any rows', () => {
        expect(findTableRows()).toHaveLength(0);
      });
    });

    describe('given dependencies with no vulnerabilities', () => {
      let dependencies;

      beforeEach(() => {
        dependencies = [
          makeDependency({ vulnerabilities: [] }),
          makeDependency({ name: 'foo', vulnerabilities: [] }),
        ];

        createComponent({
          propsData: {
            dependencies,
            isLoading: false,
          },
        });
      });

      it('renders a row for each dependency', () => {
        const rows = findTableRows();

        dependencies.forEach((dependency, i) => {
          expectDependencyRow(rows.at(i), dependency);
        });
      });

      it('does not render any row toggle buttons', () => {
        expect(findRowToggleButtons()).toHaveLength(0);
      });

      it('does not render vulnerability details', () => {
        expect(findDependencyVulnerabilities().exists()).toBe(false);
      });
    });

    describe('given some dependencies with vulnerabilities', () => {
      let dependencies;

      beforeEach(() => {
        dependencies = [
          makeDependency({ name: 'qux', vulnerabilities: ['bar', 'baz'] }),
          makeDependency({ vulnerabilities: [] }),
          // Guarantee that the component doesn't mutate these, but still
          // maintains its row-toggling behaviour (i.e., via _showDetails)
        ].map(Object.freeze);

        createComponent({
          propsData: {
            dependencies,
            isLoading: false,
          },
        });
      });

      it('renders a row for each dependency', () => {
        const rows = findTableRows();

        dependencies.forEach((dependency, i) => {
          expectDependencyRow(rows.at(i), dependency);
        });
      });

      it('render the toggle button for each row', () => {
        const toggleButtons = findRowToggleButtons();

        dependencies.forEach((dependency, i) => {
          const button = toggleButtons.at(i);

          expect(button.exists()).toBe(true);
          expect(button.classes('invisible')).toBe(dependency.vulnerabilities.length === 0);
        });
      });

      it('does not render vulnerability details', () => {
        expect(findDependencyVulnerabilities().exists()).toBe(false);
      });

      describe('the dependency vulnerabilities', () => {
        let rowIndexWithVulnerabilities;

        beforeEach(() => {
          rowIndexWithVulnerabilities = dependencies.findIndex(
            dep => dep.vulnerabilities.length > 0,
          );
        });

        it('can be displayed by clicking on the toggle button', () => {
          const toggleButton = findRowToggleButtons().at(rowIndexWithVulnerabilities);
          toggleButton.vm.$emit('click');

          return nextTick().then(() => {
            expect(findDependencyVulnerabilities().props()).toEqual({
              vulnerabilities: dependencies[rowIndexWithVulnerabilities].vulnerabilities,
            });
          });
        });

        it('can be displayed by clicking on the vulnerabilities badge', () => {
          const badge = findTableRows()
            .at(rowIndexWithVulnerabilities)
            .find(GlBadge);
          badge.trigger('click');

          return nextTick().then(() => {
            expect(findDependencyVulnerabilities().props()).toEqual({
              vulnerabilities: dependencies[rowIndexWithVulnerabilities].vulnerabilities,
            });
          });
        });
      });
    });
  });
});
