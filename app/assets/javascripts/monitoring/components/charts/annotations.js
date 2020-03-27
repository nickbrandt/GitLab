import { graphTypes, symbolSizes } from '../../constants';

/**
 * A "virtual" coordinates system for the annotation series.
 * Deployment icons, a type of annotation, are displayed
 * along the [min, max] range at height `pos`.
 */
const annotationsYAxisCoords = {
  min: 0,
  pos: 3, // 3% height of chart's grid
  max: 100,
};

/**
 * Annotation y axis min & max allows the deployment
 * icons to position correctly in the chart
 */
export const annotationsYAxis = {
  show: false,
  min: annotationsYAxisCoords.min,
  max: annotationsYAxisCoords.max,
  axisLabel: {
    // formatter fn required to trigger tooltip re-positioning
    formatter: () => {},
  },
};
/**
 * This util method check if a particular series data point
 * is of annotation type. Annotations are generally scatter
 * plot charts
 *
 * @param {String} type series component type
 * @returns {Boolean}
 */
export const isAnnotation = type => type === graphTypes.annotationsData;

/**
 * Annotations are scatter plot series that are passed
 * to eCharts along with the actual data series. As of %12.9
 * deployment icons, a type of annotations, need to be displayed on
 * the chart and a scatter plot is the most convenient way.
 *
 *
 * This method currently supports only deployments. After
 * https://gitlab.com/gitlab-org/gitlab/-/issues/211418 annotations
 * support will be added in this method.
 *
 * This method is extracted out of the charts so that
 * annotation lines can be easily supported in
 * the future.
 *
 * @param {Array} deployments deployments data
 * @returns {Object} annotation series object
 */
export const generateAnnotationsSeries = (deployments = []) => {
  if (!deployments.length) {
    return [];
  }
  const data = deployments.map(deployment => {
    return {
      name: 'deployments',
      value: [deployment.createdAt, annotationsYAxisCoords.pos],
      symbol: deployment.icon,
      symbolSize: symbolSizes.default,
      itemStyle: {
        color: deployment.color,
      },
    };
  });

  return {
    type: graphTypes.annotationsData,
    yAxisIndex: 1, // annotationsYAxis index
    data,
  };
};
