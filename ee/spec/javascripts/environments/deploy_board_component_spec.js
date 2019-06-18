import Vue from 'vue';
import DeployBoard from 'ee/environments/components/deploy_board_component.vue';
import { environment } from 'spec/environments/mock_data';
import { deployBoardMockData } from './mock_data';

describe('Deploy Board', () => {
  let DeployBoardComponent;

  beforeEach(() => {
    DeployBoardComponent = Vue.extend(DeployBoard);
  });

  describe('with valid data', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: deployBoardMockData,
          isLoading: false,
          isEmpty: false,
          logsPath: environment.log_path,
        },
      }).$mount();
    });

    it('should render percentage with completion value provided', () => {
      expect(
        component.$el.querySelector('.deploy-board-information .percentage').textContent,
      ).toEqual(`${deployBoardMockData.completion}%`);
    });

    it('should render total instance count', () => {
      const renderedTotal = component.$el.querySelector('.deploy-board-instances .total-instances');
      const actualTotal = deployBoardMockData.instances.length;

      expect(renderedTotal.textContent).toEqual(`(${actualTotal})`);
    });

    it('should render all instances', () => {
      const instances = component.$el.querySelectorAll('.deploy-board-instances-container a');

      expect(instances.length).toEqual(deployBoardMockData.instances.length);

      expect(
        instances[2].classList.contains(
          `deploy-board-instance-${deployBoardMockData.instances[2].status}`,
        ),
      ).toBe(true);
    });

    it('should render an abort and a rollback button with the provided url', () => {
      const buttons = component.$el.querySelectorAll('.deploy-board-actions a');

      expect(buttons[0].getAttribute('href')).toEqual(deployBoardMockData.rollback_url);
      expect(buttons[1].getAttribute('href')).toEqual(deployBoardMockData.abort_url);
    });
  });

  describe('with empty state', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: {},
          isLoading: false,
          isEmpty: true,
          logsPath: environment.log_path,
        },
      }).$mount();
    });

    it('should render the empty state', () => {
      expect(component.$el.querySelector('.deploy-board-empty-state-svg svg')).toBeDefined();
      expect(
        component.$el.querySelector(
          '.deploy-board-empty-state-text .deploy-board-empty-state-title',
        ).textContent,
      ).toContain('Kubernetes deployment not found');
    });
  });

  describe('with loading state', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          deployBoardData: {},
          isLoading: true,
          isEmpty: false,
          logsPath: environment.log_path,
        },
      }).$mount();
    });

    it('should render loading spinner', () => {
      expect(component.$el.querySelector('.fa-spin')).toBeDefined();
    });
  });

  describe('with hasLegacyAppLabel equal true', () => {
    let component;

    beforeEach(() => {
      component = new DeployBoardComponent({
        propsData: {
          isLoading: false,
          isEmpty: false,
          logsPath: environment.log_path,
          hasLegacyAppLabel: true,
          deployBoardData: {},
        },
      }).$mount();
    });

    it('should render legacy label warning message', () => {
      const warningMessage = component.$el.querySelector('.bs-callout-warning');

      expect(warningMessage).toBeTruthy();
      expect(warningMessage.innerText).toContain(
        'Matching on the app label has been removed for deploy boards.',
      );
    });
  });
});
