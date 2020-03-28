import { shallowMount } from '@vue/test-utils';
import DependenciesTable from 'ee/dependencies/components/dependencies_table.vue';
import DependenciesTableRow from 'ee/dependencies/components/dependencies_table_row.vue';
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
});
