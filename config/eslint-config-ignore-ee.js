const IS_EE = require('./helpers/is_ee_env');

module.exports = IS_EE ? {} : { ignorePatterns: ['ee/**/*.*'] };
