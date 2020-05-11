<script>
import * as d3 from 'd3';
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

    baseOpacity: 0.8,
    highlightIn: 1,
    highlightOut: 0.2,
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
    drawGraph(data, parseFn) {
      console.log(data, parseFn.name);

      const parsed = parseFn(data);
      const { maxNodesPerLayer, linksAndNodes } = this.transformData(parsed);

      const settings = {
        width: this.baseWidth,
        height: this.baseHeight + (maxNodesPerLayer * this.minNodeHeight),
      };

      const { links, nodes }  = createSankey(settings)(linksAndNodes);

      console.log('data:', data);
      console.log('parsed:', parsed);
      console.log('sankyfied', { links, nodes });
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
  <div>
    <div class="dag-graph-container"></div>
    <div class="annotation"></div>
  </div>
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
