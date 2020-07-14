import CEMergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { mapApprovalsResponse, mapApprovalRulesResponse } from '../mappers';
import CodeQualityComparisonWorker from '../workers/code_quality_comparison_worker';
import { s__ } from '~/locale';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);

    const blobPath = data.blob_path || {};
    this.headBlobPath = blobPath.head_path || '';
    this.baseBlobPath = blobPath.base_path || '';
    this.sastHelp = data.sast_help_path;
    this.containerScanningHelp = data.container_scanning_help_path;
    this.dastHelp = data.dast_help_path;
    this.secretScanningHelp = data.secret_scanning_help_path;
    this.dependencyScanningHelp = data.dependency_scanning_help_path;
    this.vulnerabilityFeedbackPath = data.vulnerability_feedback_path;
    this.canReadVulnerabilityFeedback = data.can_read_vulnerability_feedback;
    this.vulnerabilityFeedbackHelpPath = data.vulnerability_feedback_help_path;
    this.approvalsHelpPath = data.approvals_help_path;
    this.codequalityHelpPath = data.codequality_help_path;
    this.securityReportsPipelineId = data.pipeline_id;
    this.securityReportsPipelineIid = data.pipeline_iid;
    this.createVulnerabilityFeedbackIssuePath = data.create_vulnerability_feedback_issue_path;
    this.createVulnerabilityFeedbackMergeRequestPath =
      data.create_vulnerability_feedback_merge_request_path;
    this.createVulnerabilityFeedbackDismissalPath =
      data.create_vulnerability_feedback_dismissal_path;
    this.visualReviewAppAvailable = Boolean(data.visual_review_app_available);
    this.appUrl = gon && gon.gitlab_url;

    this.initCodeclimate(data);
    this.initBrowserPerformanceReport(data);
    this.initLoadPerformanceReport(data);
    this.licenseScanning = data.license_scanning;
    this.metricsReportsPath = data.metrics_reports_path;

    this.enabledReports = convertObjectPropsToCamelCase(data.enabled_reports);

    this.blockingMergeRequests = data.blocking_merge_requests;

    this.hasApprovalsAvailable = data.has_approvals_available;
    this.apiApprovalsPath = data.api_approvals_path;
    this.apiApprovalSettingsPath = data.api_approval_settings_path;
    this.apiApprovePath = data.api_approve_path;
    this.apiUnapprovePath = data.api_unapprove_path;
  }

  setData(data, isRebased) {
    this.initGeo(data);
    this.initApprovals();

    this.mergePipelinesEnabled = Boolean(data.merge_pipelines_enabled);
    this.mergeTrainsCount = data.merge_trains_count || 0;
    this.mergeTrainIndex = data.merge_train_index;

    super.setData(data, isRebased);
  }

  initGeo(data) {
    this.isGeoSecondaryNode = this.isGeoSecondaryNode || data.is_geo_secondary_node;
    this.geoSecondaryHelpPath = this.geoSecondaryHelpPath || data.geo_secondary_help_path;
  }

  initApprovals() {
    this.isApproved = this.isApproved || false;
    this.approvals = this.approvals || null;
    this.approvalRules = this.approvalRules || [];
  }

  setApprovals(data) {
    this.approvals = mapApprovalsResponse(data);
    this.approvalsLeft = Boolean(data.approvals_left);
    this.isApproved = data.approved || false;
    this.preventMerge = !this.isApproved;
  }

  setApprovalRules(data) {
    this.approvalRules = mapApprovalRulesResponse(data.rules, this.approvals);
  }

  initCodeclimate(data) {
    this.codeclimate = data.codeclimate;
    this.codeclimateMetrics = {
      newIssues: [],
      resolvedIssues: [],
    };
  }

  initBrowserPerformanceReport(data) {
    this.browserPerformance = data.browser_performance;
    this.browserPerformanceMetrics = {
      improved: [],
      degraded: [],
      same: [],
    };
  }

  initLoadPerformanceReport(data) {
    this.loadPerformance = data.load_performance;
    this.loadPerformanceMetrics = {
      improved: [],
      degraded: [],
      same: [],
    };
  }

  static doCodeClimateComparison(headIssues, baseIssues) {
    // Do these comparisons in worker threads to avoid blocking the main thread
    return new Promise((resolve, reject) => {
      const worker = new CodeQualityComparisonWorker();
      worker.addEventListener('message', ({ data }) =>
        data.newIssues && data.resolvedIssues ? resolve(data) : reject(data),
      );
      worker.postMessage({
        headIssues,
        baseIssues,
      });
    });
  }

  compareCodeclimateMetrics(headIssues, baseIssues, headBlobPath, baseBlobPath) {
    const parsedHeadIssues = MergeRequestStore.parseCodeclimateMetrics(headIssues, headBlobPath);
    const parsedBaseIssues = MergeRequestStore.parseCodeclimateMetrics(baseIssues, baseBlobPath);

    return MergeRequestStore.doCodeClimateComparison(parsedHeadIssues, parsedBaseIssues).then(
      response => {
        this.codeclimateMetrics.newIssues = response.newIssues;
        this.codeclimateMetrics.resolvedIssues = response.resolvedIssues;
      },
    );
  }

  compareBrowserPerformanceMetrics(headMetrics, baseMetrics) {
    const headMetricsIndexed = MergeRequestStore.normalizeBrowserPerformanceMetrics(headMetrics);
    const baseMetricsIndexed = MergeRequestStore.normalizeBrowserPerformanceMetrics(baseMetrics);
    const improved = [];
    const degraded = [];
    const same = [];

    Object.keys(headMetricsIndexed).forEach(subject => {
      const subjectMetrics = headMetricsIndexed[subject];
      Object.keys(subjectMetrics).forEach(metric => {
        const headMetricData = subjectMetrics[metric];

        if (baseMetricsIndexed[subject] && baseMetricsIndexed[subject][metric]) {
          const baseMetricData = baseMetricsIndexed[subject][metric];
          const metricData = {
            name: metric,
            path: subject,
            score: headMetricData.value,
            delta: headMetricData.value - baseMetricData.value,
          };

          if (metricData.delta !== 0) {
            const isImproved =
              headMetricData.desiredSize === 'smaller'
                ? metricData.delta < 0
                : metricData.delta > 0;

            if (isImproved) {
              improved.push(metricData);
            } else {
              degraded.push(metricData);
            }
          } else {
            same.push(metricData);
          }
        }
      });
    });

    this.browserPerformanceMetrics = { improved, degraded, same };
  }

  // normalize browser performance metrics by indexing on performance subject and metric name
  static normalizeBrowserPerformanceMetrics(browserPerformanceData) {
    const indexedSubjects = {};
    browserPerformanceData.forEach(({ subject, metrics }) => {
      const indexedMetrics = {};
      metrics.forEach(({ name, ...data }) => {
        indexedMetrics[name] = data;
      });
      indexedSubjects[subject] = indexedMetrics;
    });

    return indexedSubjects;
  }

  compareLoadPerformanceMetrics(headMetrics, baseMetrics) {
    const headMetricsIndexed = MergeRequestStore.normalizeLoadPerformanceMetrics(headMetrics);
    const baseMetricsIndexed = MergeRequestStore.normalizeLoadPerformanceMetrics(baseMetrics);
    const improved = [];
    const degraded = [];
    const same = [];

    Object.keys(headMetricsIndexed).forEach(metric => {
      const headMetricData = headMetricsIndexed[metric];
      if (metric in baseMetricsIndexed) {
        const baseMetricData = baseMetricsIndexed[metric];
        const metricData = {
          name: metric,
          score: headMetricData,
          delta: parseFloat((parseFloat(headMetricData) - parseFloat(baseMetricData)).toFixed(2)),
        };

        if (metricData.delta !== 0.0) {
          const isImproved = [s__('ciReport|RPS'), s__('ciReport|Checks')].includes(metric)
            ? metricData.delta > 0
            : metricData.delta < 0;

          if (isImproved) {
            improved.push(metricData);
          } else {
            degraded.push(metricData);
          }
        } else {
          same.push(metricData);
        }
      }
    });

    this.loadPerformanceMetrics = { improved, degraded, same };
  }

  // normalize load performance metrics for comsumption
  static normalizeLoadPerformanceMetrics(loadPerformanceData) {
    if (!('metrics' in loadPerformanceData)) return {};

    const { metrics } = loadPerformanceData;
    const indexedMetrics = {};

    Object.keys(loadPerformanceData.metrics).forEach(metric => {
      switch (metric) {
        case 'http_reqs':
          indexedMetrics[s__('ciReport|RPS')] = metrics.http_reqs.rate;
          break;
        case 'http_req_waiting':
          indexedMetrics[s__('ciReport|TTFB P90')] = metrics.http_req_waiting['p(90)'];
          indexedMetrics[s__('ciReport|TTFB P95')] = metrics.http_req_waiting['p(95)'];
          break;
        case 'checks':
          indexedMetrics[s__('ciReport|Checks')] = `${(
            (metrics.checks.passes / (metrics.checks.passes + metrics.checks.fails)) *
            100.0
          ).toFixed(2)}%`;
          break;
        default:
          break;
      }
    });

    return indexedMetrics;
  }

  static parseCodeclimateMetrics(issues = [], path = '') {
    return issues.map(issue => {
      const parsedIssue = {
        ...issue,
        name: issue.description,
      };

      if (issue.location) {
        let parseCodeQualityUrl;

        if (issue.location.path) {
          parseCodeQualityUrl = `${path}/${issue.location.path}`;
          parsedIssue.path = issue.location.path;

          if (issue.location.lines && issue.location.lines.begin) {
            parsedIssue.line = issue.location.lines.begin;
            parseCodeQualityUrl += `#L${issue.location.lines.begin}`;
          } else if (
            issue.location.positions &&
            issue.location.positions.begin &&
            issue.location.positions.begin.line
          ) {
            parsedIssue.line = issue.location.positions.begin.line;
            parseCodeQualityUrl += `#L${issue.location.positions.begin.line}`;
          }

          parsedIssue.urlPath = parseCodeQualityUrl;
        }
      }

      return parsedIssue;
    });
  }
}
