import $ from 'jquery';
import KubernetesLogs from 'ee/kubernetes_logs';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { logMockData, podMockData, mockEnvironmentData } from './kubernetes_mock_data';

describe('Kubernetes Logs', () => {
  const fixtureTemplate = 'static/environments_logs.html';
  let mockDataset;
  let kubernetesLogContainer;
  let kubernetesLog;
  let mock;
  let mockFlash;
  let podLogsAPIPath;

  preloadFixtures(fixtureTemplate);

  describe('When data is requested correctly', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => []);
      mockFlash = spyOnDependency(KubernetesLogs, 'flash').and.callFake(() => []);
      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');

      mockDataset = kubernetesLogContainer.dataset;

      podLogsAPIPath = `/${mockDataset.projectFullPath}/environments/${mockDataset.environmentId}/pods/containers/logs.json`;

      mock = new MockAdapter(axios);
      mock.onGet(mockDataset.environmentsPath).reply(200, { environments: mockEnvironmentData });
      mock.onGet(podLogsAPIPath).reply(200, { logs: logMockData, pods: podMockData });
    });

    afterEach(() => {
      mock.restore();
    });

    it('has the environment name placed on the dropdown', done => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog
        .getData()
        .then(() => {
          const dropdown = document
            .querySelector('.js-environment-dropdown')
            .querySelector('.dropdown-menu-toggle');

          expect(dropdown.textContent).toContain(mockDataset.currentEnvironmentName);
          done();
        })
        .catch(done.fail);
    });

    it('loads all environments as options of their dropdown', done => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog
        .getData()
        .then(() => {
          const options = document
            .querySelector('.js-environment-dropdown')
            .querySelectorAll('.dropdown-item');

          expect(options.length).toEqual(mockEnvironmentData.length);
          options.forEach((item, i) => {
            expect(item.textContent.trim()).toBe(mockEnvironmentData[i].name);
          });
          done();
        })
        .catch(done.fail);
    });

    it('loads all pod names as options of their dropdown', done => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog
        .getData()
        .then(() => {
          const options = document
            .querySelector('.js-pod-dropdown')
            .querySelectorAll('.dropdown-item');

          expect(options.length).toEqual(podMockData.length);
          options.forEach((item, i) => {
            expect(item.textContent.trim()).toBe(podMockData[i]);
          });
          done();
        })
        .catch(done.fail);
    });

    it('has the pod name placed on the dropdown', done => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog
        .getData()
        .then(() => {
          const podDropdown = document
            .querySelector('.js-pod-dropdown')
            .querySelector('.dropdown-menu-toggle');

          expect(podDropdown.textContent).toContain(podMockData[0]);
          done();
        })
        .catch(done.fail);
    });

    it('queries the pod log data and sets the dom elements', done => {
      const scrollSpy = spyOnDependency(KubernetesLogs, 'scrollDown').and.callThrough();
      const toggleDisableSpy = spyOnDependency(KubernetesLogs, 'toggleDisableButton').and.stub();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      expect(kubernetesLog.isLogComplete).toEqual(false);

      kubernetesLog
        .getData()
        .then(() => {
          expect(kubernetesLog.isLogComplete).toEqual(true);

          expect(document.querySelector('.js-build-output').textContent).toContain(
            logMockData[0].trim(),
          );

          expect(scrollSpy).toHaveBeenCalled();
          expect(toggleDisableSpy).toHaveBeenCalled();
          done();
        })
        .catch(done.fail);
    });

    it('asks for the pod logs from another pod', done => {
      const changePodLogSpy = spyOn(KubernetesLogs.prototype, 'getData').and.callThrough();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      kubernetesLog
        .getData()
        .then(() => {
          const podDropdown = document.querySelectorAll('.js-pod-dropdown .dropdown-menu button');
          const anotherPod = podDropdown[podDropdown.length - 1];

          anotherPod.click();

          expect(changePodLogSpy.calls.count()).toEqual(2);
          done();
        })
        .catch(done.fail);
    });

    it('clears the pod dropdown contents when pod logs are requested', done => {
      const emptySpy = spyOn($.prototype, 'empty').and.callThrough();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog
        .getData()
        .then(() => {
          // 3 elems should be emptied:
          //   1. the environment dropdown items
          //   2. the pods dropdown items
          //   3. the job log contents
          expect(emptySpy.calls.count()).toEqual(3);
          done();
        })
        .catch(done.fail);
    });

    describe('shows an alert', () => {
      it('with an error', done => {
        mock.onGet(podLogsAPIPath).reply(400);

        kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
        kubernetesLog
          .getData()
          .then(() => {
            expect(mockFlash.calls.count()).toEqual(1);
            done();
          })
          .catch(done.fail);
      });

      it('with some explicit error', done => {
        const errorMsg = 'Some k8s error';

        mock.onGet(podLogsAPIPath).reply(400, {
          message: errorMsg,
        });

        kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
        kubernetesLog
          .getData()
          .then(() => {
            expect(mockFlash.calls.count()).toEqual(1);
            expect(mockFlash.calls.argsFor(0).join()).toContain(errorMsg);
            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('XSS Protection', () => {
    const hackyPodName = '">&lt;img src=x onerror=alert(document.domain)&gt; production';
    beforeEach(() => {
      loadFixtures(fixtureTemplate);
      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [hackyPodName]);
      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');

      mock = new MockAdapter(axios);
      mock.onGet(podLogsAPIPath).reply(200, { logs: logMockData, pods: [hackyPodName] });
    });

    afterEach(() => {
      mock.restore();
    });

    it('escapes the pod name', () => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      expect(kubernetesLog.podName).toContain(
        '&quot;&gt;&amp;lt;img src=x onerror=alert(document.domain)&amp;gt; production',
      );
    });
  });

  describe('When data is not yet loaded into cache', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);
      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [podMockData[1]]);
      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');

      // override setTimeout, to simulate polling
      const origSetTimeout = window.setTimeout;
      spyOn(window, 'setTimeout').and.callFake(cb => origSetTimeout(cb, 0));

      mockDataset = kubernetesLogContainer.dataset;

      podLogsAPIPath = `/${mockDataset.projectFullPath}/environments/${
        mockDataset.environmentId
      }/pods/${podMockData[1]}/containers/logs.json`;

      mock = new MockAdapter(axios);
      mock.onGet(mockDataset.environmentsPath).reply(200, { environments: mockEnvironmentData });
      // Simulate reactive cache, 2 tries needed
      mock.onGet(podLogsAPIPath).replyOnce(202);
      mock.onGet(podLogsAPIPath).reply(200, { logs: logMockData, pods: podMockData });
    });

    it('queries the pod log data polling for reactive cache', done => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      expect(kubernetesLog.isLogComplete).toEqual(false);

      kubernetesLog
        .getData()
        .then(() => {
          const calls = mock.history.get.filter(r => r.url === podLogsAPIPath);

          // expect 2 tries
          expect(calls.length).toEqual(2);

          expect(document.querySelector('.js-build-output').textContent).toContain(
            logMockData[0].trim(),
          );

          done();
        })
        .catch(done.fail);
    });

    afterEach(() => {
      mock.restore();
    });
  });

  describe('When data is requested with a pod name', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);
      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [podMockData[2]]);
      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');

      podLogsAPIPath = `/${mockDataset.projectFullPath}/environments/${
        mockDataset.environmentId
      }/pods/${podMockData[2]}/containers/logs.json`;

      mock = new MockAdapter(axios);
    });

    it('logs are loaded with the correct pod_name parameter', done => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog
        .getData()
        .then(() => {
          const logsCall = mock.history.get.filter(call => call.url === podLogsAPIPath);

          expect(logsCall.length).toBe(1);
          done();
        })
        .catch(done.fail);
    });

    afterEach(() => {
      mock.restore();
    });
  });
});
