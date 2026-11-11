const express = require('express');
const { validatePayment } = require('./payments');

// Step 1. Read the version and environment. The image sets APP_VERSION and the ConfigMap sets APP_ENV.
const APP_VERSION = process.env.APP_VERSION || require('../package.json').version;
const APP_ENV = process.env.APP_ENV || 'local';

const app = express();
app.use(express.json());

// Step 2. Log every request as one JSON line. The monitoring script counts these lines.
app.use((req, res, next) => {
  res.on('finish', () => {
    console.log(JSON.stringify({ time: new Date().toISOString(), method: req.method, path: req.path, status: res.statusCode }));
  });
  next();
});

// Step 3. Health check used by Kubernetes probes and the Jenkins smoke test.
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'kk-payments', version: APP_VERSION, environment: APP_ENV });
});

app.post('/payments', (req, res) => {
  const result = validatePayment(req.body);
  if (!result.valid) {
    return res.status(400).json({ errors: result.errors });
  }
  return res.status(202).json({ status: 'accepted', amount: req.body.amount });
});

module.exports = app;
