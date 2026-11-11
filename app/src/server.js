const app = require('./app');

const port = process.env.PORT || 3001;
app.listen(port, () => {
  console.log(`kk-payments listening on port ${port} (${process.env.APP_ENV || 'local'})`);
});
