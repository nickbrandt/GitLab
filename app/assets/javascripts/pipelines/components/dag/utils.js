import * as d3 from 'd3';
import {
  sankey,
  sankeyLeft,
} from 'd3-sankey';

export const removeOrphanNodes = (sankeyfiedNodes) => {
  return sankeyfiedNodes.filter((node) => node.sourceLinks.length || node.targetLinks.length)
}

export const getMaxNodes = (nodes) => {
  const counts = nodes.reduce((acc, currentNode) => {

    if (!acc[currentNode.layer]) {
      acc[currentNode.layer] = 0;
    }

    acc[currentNode.layer] += 1;

    return acc;

  }, []);

  return Math.max(...counts);
}

export const transformData = (data) => {
  const baseLayout = createSankey({ height: 10, width: 10 })(data);
  const cleanedNodes = removeOrphanNodes(baseLayout.nodes);
  const maxNodesPerLayer = getMaxNodes(cleanedNodes);

  return {
    maxNodesPerLayer,
    linksAndNodes: {
      links: data.links,
      nodes: cleanedNodes
    }
  }
}

/** transform data to give us the Sankey nodes & links
  input is:
  [stages]
    stages: {name, title, groups}
      groups: [{ name, needs }]; name is a dagJobName
        needs: [dagJobName]

  output is:
  { nodes: [node], links: [link] }
    node: { name, category }, + unused needs info
    link: { source, target, value }, with source & target node names

  CREATE NODES
  (This would be easier if the data were provided with the stage name in each group object)
  stages.groups.names -> node.name (aka dagJobName)
  stages.name -> node.category (this will change)

  CREATE LINKS
  stages.groups.name -> target
  stages.groups.needs.each -> source
  10 -> value (constant, fiddle for looks)

  DEDUPE LINKS
  Is it possible and desirable to not show that say job 4 depends on 1 and 2,
  since it implicitly depends on 2?
**/

export const parseData = (data) => {
  // stages is data here

  // this unpacking / flattening could happen on the backend
  // and that would save the highest performance expense
  const groups = data
    .map(({ groups }, idx, stages) => {
      return groups.map((group) => {
        return { ...group, category: stages[idx].name };
      });
    })
    .flat();

  // In theory, groups could be processed to remove unnecessary link
  // information but I'm not sure it's a problem just now
  const nodes = groups;

  const links = groups
    .filter(({ needs }) => needs)
    .map(({ needs, name }) => {
      return needs.map((job) => {
        return { source: job, target: name, value: 10 };
      });
    })
    .flat();

  const filteredLinks = () => {
    const nodeDict = nodes.reduce((acc, node) => {
      acc[node.name] = node;
      return acc;
    }, {});

    const getAllAncestors = (nodes) => {
      const needs = nodes
        .map((node) => nodeDict[node].needs || '')
        .flat()
        .filter(Boolean);

      if (needs.length) {
        return [...needs, ...getAllAncestors(needs)];
      }

      return [];
    };

    return links.filter((link) => {
      const targetNode = link.target;
      const targetNodeNeeds = nodeDict[targetNode].needs;
      const targetNodeNeedsMinusSource = targetNodeNeeds.filter(
        (need) => need !== link.source
      );
      const allAncestors = getAllAncestors(targetNodeNeedsMinusSource, []);

      return !allAncestors.includes(link.source);
    });

    /*

    for every link, check out it's target
    for every target, get the target node's needs
    then drop the current link source from that list

    call a function to get all ancestors, recursively
    is the current link's source in the list of all parents
    then we drop this link

    */
  };

  return { nodes, links: filteredLinks() };
};

export const parseNestedData = (data) => {
  // stages is data here

  // this unpacking / flattening could happen on the backend
  // and that would save the highest performance expense
  const groups = data
    .map(({ groups }, idx, stages) => {
      return groups.map((group) => {
        return { ...group, category: stages[idx].name };
      });
    })
    .flat();

  // In theory, groups could be processed to remove unnecessary link
  // information but I'm not sure it's a problem just now
  const nodes = groups;

  const links = groups
    .map((group) => {

      return group.jobs.map((job) => {
        if (!job.needs) {
          return [];
        }

        return job.needs.map((needed) => {
          return { source: needed, target: group.name, value: (group.size * 10), group: group.name };
        });
      })
    }).flat(2)


  const filteredLinks = () => {
    const nodeDict = nodes.reduce((acc, node) => {
      acc[node.name] = node;
      return acc;
    }, {});


    const getAllAncestors = (nodes) => {
      const needs = nodes
        .map((node) => nodeDict[node].needs || '')
        .flat()
        .filter(Boolean);

      if (needs.length) {
        return [...needs, ...getAllAncestors(needs)];
      }

      return [];
    };

    return links.filter((link) => {
      const targetNode = link.target;
      const targetNodeNeeds = nodeDict[targetNode].jobs.map(({ needs }) => needs || []).flat();
      const targetNodeNeedsMinusSource = targetNodeNeeds.filter(
        (need) => need !== link.source
      );
      const allAncestors = getAllAncestors(targetNodeNeedsMinusSource, []);

      return !allAncestors.includes(link.source);
    });

    /*

    for every link, check out it's target
    for every target, get the target node's needs
    then drop the current link source from that list

    call a function to get all ancestors, recursively
    is the current link's source in the list of all parents
    then we drop this link

    */
  };

  return { nodes, links: filteredLinks() };
};

export const createSankey = ({ width, height, nodeWidth, nodePadding }) => {
  const sankeyGenerator = sankey()
    .nodeId((d) => d.name)
    .nodeAlign(sankeyLeft)
    .nodeWidth(nodeWidth)
    .nodePadding(nodePadding)
    .extent([
      [100, 5],
      [width - 100, height - 105],
    ]);
  return ({ nodes, links }) =>
    sankeyGenerator({
      nodes: nodes.map((d) => Object.assign({}, d)),
      links: links.map((d) => Object.assign({}, d)),
    });
};
