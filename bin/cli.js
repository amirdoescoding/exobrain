#!/usr/bin/env node
'use strict';

const { execSync } = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');

if (os.platform() !== 'darwin') {
  console.error('ExoBrain currently supports macOS only.');
  console.error('Windows and Linux support is coming in a future release.');
  process.exit(1);
}

const setupScript = path.join(__dirname, '..', 'setup.sh');

if (!fs.existsSync(setupScript)) {
  console.error('setup.sh not found. Please re-install: npx exobrain');
  process.exit(1);
}

try {
  execSync(`bash "${setupScript}"`, { stdio: 'inherit' });
} catch (e) {
  process.exit(e.status ?? 1);
}
