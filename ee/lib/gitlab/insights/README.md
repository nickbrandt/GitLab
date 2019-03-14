## Gitlab::Insights

The goal of the `Gitlab::Insights::` classes is to:

1. Find the raw data (issuables),
1. Reduce them depending on certain conditions,
1. Serialize the reduced data into a payload that can be JSON'ed and used on the
  frontend by the graphing library.

### Architecture diagram

```mermaid
graph TD
subgraph Gitlab::Insights::
    A[Finders::] --> |"returns issuables Active Record (AR) relation"| B;
    B[Reducers::] --> |reduces issuables AR relation into a hash of chart data| C
    C[Serializers::] --> |serializes chart data to be consumable by the frontend and the charting library| D
    D(JSON-compatible payload used by the frontend to build the chart)
    end
```

#### Specific example

```mermaid
graph TD
subgraph Gitlab::Insights::
    A[Finders::IssuableFinder] --> B;
    B[Reducers::LabelCountPerPeriodReducer] --> C
    C[Serializers::Chartjs::MultiSeriesSerializer] --> D
    D(JSON-compatible payload used by the frontend to build the graph)
    end
```
