const express = require('express');
const cors = require('cors');
const apiRouter = require('./routers/api.router');
require('./databases/mysql.db');

const app = express();
app.use(express.json());

// CORS ouvert pour usage interne au cluster
app.use(cors());

app.get('/', (req, res) => res.send('API running'));
app.use('/api', apiRouter);

module.exports = app;
