import { shallowMount } from '@vue/test-utils';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';

describe('Pagination component', () => {
  let wrapper;
  let spy;

  const mountComponent = props => {
    wrapper = shallowMount(TablePagination, {
      propsData: props,
    });
  };

  beforeEach(() => {
    spy = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('render', () => {
    it('should not render anything', () => {
      mountComponent({
        pageInfo: {
          nextPage: NaN,
          page: 1,
          perPage: 20,
          previousPage: NaN,
          total: 15,
          totalPages: 1,
        },
        change: spy,
      });

      expect(wrapper.isEmpty()).toBe(true);
    });

    describe('prev button', () => {
      it('should be disabled and non clickable', () => {
        mountComponent({
          pageInfo: {
            nextPage: 2,
            page: 1,
            perPage: 20,
            previousPage: NaN,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        expect(wrapper.find('.js-previous-button').classes()).toContain('disabled');
        wrapper.find('.js-previous-button .page-link').trigger('click');
        expect(spy).not.toHaveBeenCalled();
      });

      it('should be disabled and non clickable when total and totalPages are NaN', () => {
        mountComponent({
          pageInfo: {
            nextPage: 2,
            page: 1,
            perPage: 20,
            previousPage: NaN,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        expect(wrapper.find('.js-previous-button').classes()).toContain('disabled');
        wrapper.find('.js-previous-button .page-link').trigger('click');
        expect(spy).not.toHaveBeenCalled();
      });

      it('should be enabled and clickable', () => {
        mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });
        wrapper.find('.js-previous-button .page-link').trigger('click');
        expect(spy).toHaveBeenCalledWith(1);
      });

      it('should be enabled and clickable when total and totalPages are NaN', () => {
        mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        wrapper.find('.js-previous-button .page-link').trigger('click');
        expect(spy).toHaveBeenCalledWith(1);
      });
    });

    describe('first button', () => {
      it('should call the change callback with the first page', () => {
        mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });
        const button = wrapper.find('.js-first-button .page-link');
        expect(button.text().trim()).toEqual('« First');
        button.trigger('click');
        expect(spy).toHaveBeenCalledWith(1);
      });

      it('should call the change callback with the first page when total and totalPages are NaN', () => {
        mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        const button = wrapper.find('.js-first-button .page-link');
        expect(button.text().trim()).toEqual('« First');
        button.trigger('click');
        expect(spy).toHaveBeenCalledWith(1);
      });
    });

    describe('last button', () => {
      it('should call the change callback with the last page', () => {
        mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });
        const button = wrapper.find('.js-last-button .page-link');
        expect(button.text().trim()).toEqual('Last »');
        button.trigger('click');
        expect(spy).toHaveBeenCalledWith(5);
      });

      it('should not render', () => {
        mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        expect(wrapper.find('.js-last-button .page-link').exists()).toBe(false);
      });
    });

    describe('next button', () => {
      it('should be disabled and non clickable', () => {
        mountComponent({
          pageInfo: {
            nextPage: NaN,
            page: 5,
            perPage: 20,
            previousPage: 4,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });
        expect(
          wrapper
            .find('.js-next-button')
            .text()
            .trim(),
        ).toEqual('Next ›');
        wrapper.find('.js-next-button .page-link').trigger('click');
        expect(spy).not.toHaveBeenCalled();
      });

      it('should be disabled and non clickable when total and totalPages are NaN', () => {
        mountComponent({
          pageInfo: {
            nextPage: NaN,
            page: 5,
            perPage: 20,
            previousPage: 4,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        expect(
          wrapper
            .find('.js-next-button')
            .text()
            .trim(),
        ).toEqual('Next ›');
        wrapper.find('.js-next-button .page-link').trigger('click');
        expect(spy).not.toHaveBeenCalled();
      });

      it('should be enabled and clickable', () => {
        mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });
        wrapper.find('.js-next-button .page-link').trigger('click');
        expect(spy).toHaveBeenCalledWith(4);
      });

      it('should be enabled and clickable when total and totalPages are NaN', () => {
        mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        wrapper.find('.js-next-button .page-link').trigger('click');
        expect(spy).toHaveBeenCalledWith(4);
      });
    });

    describe('numbered buttons', () => {
      it('should render 5 pages', () => {
        mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });
        expect(wrapper.vm.$el.querySelectorAll('.page').length).toEqual(5);
      });

      it('should not render any page', () => {
        mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        expect(wrapper.vm.$el.querySelectorAll('.page').length).toEqual(0);
      });
    });

    describe('spread operator', () => {
      it('should render', () => {
        mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: 84,
            totalPages: 10,
          },
          change: spy,
        });
        expect(
          wrapper
            .find('.separator')
            .text()
            .trim(),
        ).toEqual('...');
      });

      it('should not render', () => {
        mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });
        expect(wrapper.find('.separator').exists()).toBe(false);
      });
    });
  });
});
