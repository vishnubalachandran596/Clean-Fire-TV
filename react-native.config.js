module.exports = {
  // CleanHomeShell autolink temporarily disabled — native .so load was crashing
  // interactive main before dock UI could go VISIBLE. Re-enable after stable.
  dependency: {
    platforms: {
      kepler: {
        autolink: {},
      },
    },
  },
};
