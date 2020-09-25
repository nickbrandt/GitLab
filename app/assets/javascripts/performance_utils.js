const processMeasures = measures => {
  measures.forEach(measure => {
    window.requestAnimationFrame(() =>
      performance.measure(measure.name, measure.start, measure.end),
    );
  });
};

export const performanceMeasureAfterRendering = ({ marks = [], measures = [] } = {}) => {
  window.requestAnimationFrame(() => {
    if (marks.length) {
      marks.forEach(mark => {
        if (!performance.getEntriesByName(mark).length) {
          performance.mark(mark);
          processMeasures(measures);
        }
      });
    } else {
      processMeasures(measures);
    }
  });
};
export const performanceMark = mark => {
  window.requestAnimationFrame(() => {
    performance.mark(mark);
  });
};
