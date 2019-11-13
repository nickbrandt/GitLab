import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { getParameterValues, redirectTo } from '~/lib/utils/url_utility';
import { isScrolledToBottom, scrollDown, toggleDisableButton } from '~/lib/utils/scroll_utils';
import httpStatusCodes from '~/lib/utils/http_status';
import LogOutputBehaviours from '~/lib/utils/logoutput_behaviours';
import flash from '~/flash';
import { s__, sprintf } from '~/locale';
import _ from 'underscore';
import { backOff } from '~/lib/utils/common_utils';
import Api from 'ee/api';

const TWO_MINUTES = 120000;

const requestWithBackoff = (projectPath, environmentId, podName, containerName) =>
  backOff((next, stop) => {
    Api.getPodLogs({ projectPath, environmentId, podName, containerName })
      .then(res => {
        if (!res.data) {
          next();
          return;
        }
        stop(res);
      })
      .catch(err => {
        stop(err);
      });
  }, TWO_MINUTES);

export default class KubernetesPodLogs extends LogOutputBehaviours {
  constructor(container) {
    super();
    this.options = $(container).data();

    const {
      currentEnvironmentName,
      environmentsPath,
      projectFullPath,
      environmentId,
    } = this.options;
    this.environmentName = currentEnvironmentName;
    this.environmentsPath = environmentsPath;
    this.projectFullPath = projectFullPath;
    this.environmentId = environmentId;

    [this.podName] = getParameterValues('pod_name');
    if (this.podName) {
      this.podName = _.escape(this.podName);
    }

    this.$window = $(window);
    this.$buildOutputContainer = $(container).find('.js-build-output');
    this.$refreshLogBtn = $(container).find('.js-refresh-log');
    this.$buildRefreshAnimation = $(container).find('.js-build-refresh');
    this.$podDropdown = $(container).find('.js-pod-dropdown');
    this.$envDropdown = $(container).find('.js-environment-dropdown');

    this.isLogComplete = false;

    this.scrollThrottled = _.throttle(this.toggleScroll.bind(this), 100);
    this.$window.off('scroll').on('scroll', () => {
      if (!isScrolledToBottom()) {
        this.toggleScrollAnimation(false);
      } else if (isScrolledToBottom() && !this.isLogComplete) {
        this.toggleScrollAnimation(true);
      }
      this.scrollThrottled();
    });

    this.$refreshLogBtn.off('click').on('click', this.getData.bind(this));
  }

  scrollToBottom() {
    scrollDown();
    this.toggleScroll();
  }

  scrollToTop() {
    $(document).scrollTop(0);
    this.toggleScroll();
  }

  getData() {
    this.scrollToTop();
    this.$buildOutputContainer.empty();
    this.$buildRefreshAnimation.show();
    toggleDisableButton(this.$refreshLogBtn, 'true');

    return Promise.all([this.getEnvironments(), this.getLogs()]);
  }

  getEnvironments() {
    return axios
      .get(this.environmentsPath)
      .then(res => {
        const { environments } = res.data;
        this.setupEnvironmentsDropdown(environments);
      })
      .catch(() => flash(s__('Environments|An error occurred while fetching the environments.')));
  }

  getLogs() {
    return requestWithBackoff(this.projectFullPath, this.environmentId, this.podName)
      .then(res => {
        const { logs, pods } = res.data;
        this.setupPodsDropdown(pods);
        this.displayLogs(logs);
      })
      .catch(err => {
        const { response } = err;
        if (response && response.status === httpStatusCodes.BAD_REQUEST) {
          if (response.data && response.data.message) {
            flash(
              sprintf(
                s__('Environments|An error occurred while fetching the logs - Error: %{message}'),
                {
                  message: response.data.message,
                },
              ),
              'notice',
            );
          } else {
            flash(
              s__(
                'Environments|An error occurred while fetching the logs for this environment or pod. Please try again',
              ),
              'notice',
            );
          }
        } else {
          flash(s__('Environments|An error occurred while fetching the logs'));
        }
      })
      .finally(() => {
        this.$buildRefreshAnimation.hide();
      });
  }

  setupEnvironmentsDropdown(environments) {
    this.setupDropdown(
      this.$envDropdown,
      this.environmentName,
      environments.map(({ name, logs_path }) => ({ name, value: logs_path })),
      el => {
        const url = el.currentTarget.value;
        redirectTo(url);
      },
    );
  }

  setupPodsDropdown(pods) {
    // Show first pod, it is selected by default
    this.podName = this.podName || pods[0];
    this.setupDropdown(
      this.$podDropdown,
      this.podName,
      pods.map(podName => ({ name: podName, value: podName })),
      el => {
        const selectedPodName = el.currentTarget.value;
        if (selectedPodName !== this.podName) {
          this.podName = selectedPodName;
          this.getData();
        }
      },
    );
  }

  displayLogs(logs) {
    const formattedLogs = logs.map(logEntry => `${_.escape(logEntry)} <br />`);

    this.$buildOutputContainer.append(formattedLogs);
    scrollDown();
    this.isLogComplete = true;
    toggleDisableButton(this.$refreshLogBtn, false);
  }

  setupDropdown($dropdown, activeOption = '', options, onSelect) {
    const $dropdownMenu = $dropdown.find('.dropdown-menu');

    $dropdown
      .find('.dropdown-menu-toggle')
      .html(
        `<span class="dropdown-toggle-text text-truncate">${activeOption}</span><i class="fa fa-chevron-down"></i>`,
      );

    $dropdownMenu.off('click');
    $dropdownMenu.empty();

    options.forEach(option => {
      $dropdownMenu.append(`
        <button class='dropdown-item' value='${option.value}'>
          ${_.escape(option.name)}
        </button>
      `);
    });

    $dropdownMenu.find('button').on('click', onSelect.bind(this));
  }
}
