<script>
import * as d3 from 'd3';

import { uniqueId } from 'lodash';
import mockDAGdata from './dag-data/mockDAGdata.json'
import gitlabDAGdata from './dag-data/gitlabDAGdata.json'
import groupDAGdata from './dag-data/groupDAGdata.json'
import {
  createSankey,
  getMaxNodes,
  parseData,
  parseNestedData,
  removeOrphanNodes,
} from './utils'

export default {
  name: 'Dag',
  viewOptions: {
    baseHeight: 200,
    baseWidth: 1000,
    minNodeHeight: 60,
    nodeWidth: 15,
    nodePadding: 25,

    // can plausibly applied through CSS instead, TBD
    baseOpacity: 0.8,
    highlightIn: 1,
    highlightOut: 0.2,

    // just for exploration, to be removed on design decision
    categorizeBy: 'name', // category | name
    linkType: 'start', // start | end | gradient
    colorNodes: true,
    strokeNodes: false,
    blendMode: '',
  },
  gitLabColorRotation: [
    '#e17223',
    '#83ab4a',
    '#5772ff',
    '#b24800',
    '#25d2d2',
    '#006887',
    '#487900',
    '#d84280',
    '#3547de',
    '#6f3500',
    '#006887',
    '#275600',
    '#b31756',
  ],
  data: function() {
    return {
      color: () => {},
      width: 0,
      height: 0,
    }
  },
  mounted() {
    const {
      details: { stages: simplified },
    } = mockDAGdata;

    const {
      details: { stages: stages },
    } = gitlabDAGdata;

    const {
      details: { stages: nestedStages },
    } = groupDAGdata;

    this.drawGraph(simplified, parseData);
    this.drawGraph(stages, parseData);
    this.drawGraph(nestedStages, parseNestedData);

  },
  methods: {
    addSvg() {
       return d3
        .select('.dag-graph-container')
        .append('svg')
        .attr('viewBox', [0, 0, this.width, this.height])
        .attr('width', this.width)
        .attr('height', this.height);
    },
    generateLinks (svg, linksData) {
      return svg
        .append('g')
        .attr('fill', 'none')
        .attr('stroke-opacity', this.$options.viewOptions.baseOpacity)
        .selectAll('.link')
        .data(linksData)
        .enter()
        .append('g')
        .attr('id', (d) => d.uid = uniqueId('link'))
        .style('mix-blend-mode', this.$options.viewOptions.blendMode)
        .classed('link', true)
    },
    appendLinks(link) {
      const strokeColor = (d, i) => {
          switch (this.$options.viewOptions.linkType) {
            case 'gradient':
              return `url(#${d.gradId})`
            case 'start':
              return this.color(d.source);
            case 'end':
              return this.color(d.target);
            default:
              return this.$options.gitLabColorRotation[i % gitLabColorRotation.length]
          }
        }

        const widerCorners = (d, i) => {
          const xValRaw = (d.source.x1 + ((i + 1) * d.width) % ((d.target.x1 - d.source.x0)));
          const xValMin = Math.max((xValRaw + this.$options.viewOptions.nodeWidth), d.width);
          /**
            Math.random adds a little blur, so the  don't sit right on one another
            Increasing the value it is multipled by will increase the blur
          **/
          const midPointX = Math.min(xValMin, (d.target.x0 - ((2 * this.$options.viewOptions.nodeWidth * Math.random()))))

          return d3.line()([
            [d.source.x0, d.y0],
            [midPointX, d.y0],
            [midPointX, d.y1],
            [d.target.x1, d.y1],
          ]);
        }

        link
          .append('path')
          .attr('d', widerCorners)
          .attr('stroke', strokeColor)
          .style('stroke-linejoin', 'round')
          // minus two to account for the rounded nodes
          .attr('stroke-width', (d) => Math.max(1, d.width - 2));
          // .attr('clip-path', (d) => `url(#${d.clipId})`);
    },
    createClip() {
      const clip = (d) => `
        M${d.source.x0}, ${d.y1}
        V${Math.max(Math.max(d.y1, d.y0) + (d.width / 2), d.y0, d.y1)}
        H${d.target.x1}
        V${Math.min(Math.min(d.y0, d.y1) - (d.width / 2), d.y0, d.y1)}
        H${d.source.x0}
        Z`

      this.link
        .append('clipPath')
        .attr('id', (d) => (d.clipId = uniqueId('clip')))
        .append('path')
        .attr('d', clip)
    },
    createGradient() {
      this.gradient = this.link
        .append('linearGradient')
        .attr('id', (d) => (d.gradId = uniqueId('grad')))
        .attr('gradientUnits', 'userSpaceOnUse')
        .attr('x1', (d) => d.source.x1)
        .attr('x2', (d) => d.target.x0);

      this.gradient
        .append('stop')
        .attr('offset', '0%')
        .attr('stop-color', (d) => this.color(d.source));

      this.gradient
        .append('stop')
        .attr('offset', '100%')
        .attr('stop-color', (d) => this.color(d.target));
    },
    createLinks (svg, linksData) {
      let link;
      link = this.generateLinks(svg, linksData);
      // this.createGradient();
      // this.createClip();
      this.appendLinks(link);
    },
    drawGraph(data, parseFn) {

      const {
        baseWidth,
        baseHeight,
        categorizeBy,
        minNodeHeight,
        nodeWidth,
        nodePadding,
      } = this.$options.viewOptions;

      const parsed = parseFn(data);
      const { maxNodesPerLayer, linksAndNodes } = this.transformData(parsed);

      this.width = baseWidth;
      this.height= baseHeight + (maxNodesPerLayer * minNodeHeight)

      const layout = createSankey({
        width: this.width,
        height: this.height,
        nodeWidth,
        nodePadding,
      })(linksAndNodes);

      console.log('data:', data);
      console.log('parsed:', parsed);
      console.log('sankyfied', layout);

      this.initColors(categorizeBy);

      const svg = this.addSvg();
      this.createLinks(svg, layout.links);
      // createNodes(svg, nodes, settings, color);


    },

    initColors (colorProp) {
      const col = d3.scaleOrdinal(this.$options.gitLabColorRotation);
      this.color = (d) => col(d[colorProp]);
    },

    transformData (data) {
      const { nodeWidth, nodePadding } = this.$options.viewOptions;
      const baseLayout = createSankey({ height: 10, width: 10, nodeWidth, nodePadding })(data);
      const cleanedNodes = removeOrphanNodes(baseLayout.nodes);
      const maxNodesPerLayer = getMaxNodes(cleanedNodes);

      return {
        maxNodesPerLayer,
        linksAndNodes: {
          links: data.links,
          nodes: cleanedNodes
        }
      }
    },
  }
};

</script>
<template>
  <div class="dag-graph-container"></div>
</template>

<style scoped>
  .dag-graph-container {
    display: flex;
    position: relative;
    justify-content: flex-start;
    flex-direction: column;
  }

  .annotation {
    position: fixed;
    padding: 1rem;
    top: .5rem;
    right: .5rem;
    width: max-content;
    background-color: white;
  }

  .shadow {
    box-shadow: 0px 0px 8px bisque;
  }

  .label {
    pointer-events: none;
  }

  .link, .junction-points {
    cursor: pointer;
  }

  p {
    margin: 0;
  }

  svg:not(:first-of-type) {
    margin-top: 14rem;
    margin-bottom: 5rem;
  }
</style>
