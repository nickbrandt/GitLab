/**
 * Adds the line number property
 * @param Object line
 * @param Number lineNumber
 */
export const parseLine = (line = {}, lineNumber) => ({
  ...line,
  lineNumber,
});

/**
 * When a line has `section_header` set to true, we create a new
 * structure to allow to nest the lines that belong to the
 * collpasible section
 *
 * @param Object line
 * @param Number lineNumber
 */
export const parseHeaderLine = (line = {}, lineNumber) => ({
  isClosed: true,
  isHeader: true,
  line: parseLine(line, lineNumber),
  lines: [],
});

/**
 * `section_duration` is sent in the end of the
 * collpasibl;e section
 *
 * Finds the section it belongs to and adds it to the correct
 * object
 *
 * @param Array data
 * @param Object durationLine
 */
export function addDurationToHeader(data, durationLine) {
  data.forEach(el => {
    if (el.line && el.line.section === durationLine.section) {
      el.line.section_duration = durationLine.section_duration;
    }
  });
}

/**
 * Parses the job log content into a structure usable by the template
 *
 * For collaspible lines (section_header = true):
 *    - creates a new array to hold the lines that are collpasible,
 *    - adds a isClosed property to handle toggle
 *    - adds a isHeader property to handle template logic
 *    - adds the section_duration
 * For each line:
 *    - adds the index as lineNumber
 *
 * @param {Array} lines
 * @returns {Array}
 */
export const logLinesParser = (lines = [], lineNumberStart, accumulator = []) =>
  lines.reduce((acc, line, index) => {
    const lineNumber = lineNumberStart ? lineNumberStart + index : index;
    const last = acc[acc.length - 1];

    if (line.section_header) {
      acc.push(parseHeaderLine(line, lineNumber));
    } else if (
      last &&
      last.isHeader &&
      !line.section_duration &&
      line.section === last.line.section
    ) {
      last.lines.push(parseLine(line, lineNumber));
    } else if (line.section_duration) {
      addDurationToHeader(acc, line);
    } else {
      acc.push(parseLine(line, lineNumber));
    }

    return acc;
  }, accumulator);

/**
 * Finds the repeated offset, removes the old one
 * Returns a new object with the updated log without
 * the repeated offset and the last line number.
 *
 * @param Array newLog
 * @param Array oldParsed
 * @returns Object
 *
 */
export const findOffsetAndRemove = (newLog, oldParsed) => {
  const cloneOldLog = [...oldParsed];
  const lastIndex = cloneOldLog.length - 1;
  const last = cloneOldLog[lastIndex];

  const firstNew = newLog[0];
  const parsed = {};

  if((last.offset === firstNew.offset) || (last.line && last.line.offset === firstNew.offset)) {
    cloneOldLog.splice(lastIndex);
    parsed.lastLine = last.lineNumber;
  } else if (last.lines && last.lines.length) {
    const lastNestedIndex = last.lines.length - 1;
    const lastNested = last.lines[lastNestedIndex];
    if (lastNested.offset === firstNew.offset) {
      last.lines.splice(lastNestedIndex);
      parsed.lastLine = lastNested.lineNumber;
    }
  }
  return cloneOldLog;
};

export const findLastLineNumber = (oldLog) => {
  const lastIndex = oldLog.length - 1;

  if (oldLog[lastIndex].lines && oldLog[lastIndex].lines.length) {
    return oldLog[lastIndex].lines.length -1
  } else if (oldLog.length === 1) {
    return 1;
  } else {
    return lastIndex;
  }
}

/**
 * The first line of the new log may already exist
 *
 * Removes the old line if the offset is the same
 * Parses the new incremented log
 *
 * @param Arrary newLog
 * @param Array oldParsed
 * @returns Array
 */
export const updateIncrementalTrace = (newLog, oldParsed = []) => {
  const parsedLog = findOffsetAndRemove(newLog, oldParsed);
  const lineNumber = findLastLineNumber(oldParsed);
  console.log('lineNumber', lineNumber);
  return logLinesParser(newLog, lineNumber, parsedLog);
};

export const isNewJobLogActive = () => gon && gon.features && gon.features.jobLogJson;
