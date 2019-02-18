var express = require('express');
var app = express();
const request = require('request-promise-native')
var healthy=true;
var headers;

const upstream_uri = process.env.UPSTREAM_URI || 'http://worldclockapi.com/api/json/utc/now'
const service_name = process.env.SERVICE_NAME || 'ist_service'

//CORS middleware
var allowCrossDomain = function(req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'OPTIONS,GET,PUT,POST,DELETE');
  res.header('Access-Control-Allow-Headers', 'Content-Type');

  next();
}

app.use(allowCrossDomain);
app.use(express.static(__dirname + '/public'));
app.set('port', (process.env.api_port));


app.get('/', async(req, res) => {
  const begin = Date.now()
  headers = {}

  // Forward Headers for tracing
  // headers = forwardTraceHeaders(req);

  // Forward Headers for canary and failure requests
  headers = forwardCanaryAndFailureHeaders(req);

  // Do Bad Things
  // createIssues(req, res);

  let up
  try {
    up = await request({
      url: upstream_uri,
      headers: headers
    })
  } catch (error) {
    up = error
  }
  const timeSpent = (Date.now() - begin) / 1000 + "secs "

  res.write(`I am the canary hiding :-/ calling - ${upstream_uri}`);
  res.write(`calling - ${upstream_uri}`);
  res.end(`\n${service_name} exec duration --- ${timeSpent}\n${upstream_uri} -> ${up}\n\n`);
})

app.get('/health', function(req, res) {
  if (healthy)
    res.end();
  else
    res.status(503).send([]);
})

app.get('/health/toggle', function(req, res){
  healthy = !healthy;
  res.end();
})

function forwardTraceHeaders(req) {
  incoming_headers = [
    'x-request-id',
    'x-b3-traceid',
    'x-b3-spanid',
    'x-b3-parentspanid',
    'x-b3-sampled',
    'x-b3-flags',
    'x-ot-span-context'
  ]
  const headers = {}
  for (let h of incoming_headers) {
    if (req.header(h))
      headers[h] = req.header(h)
  }
  return headers
}

function forwardCanaryAndFailureHeaders(req) {
  incoming_headers = [
    'x-dev-user',
    'fail'
  ]
  const headers = {}
  for (let h of incoming_headers) {
    if (req.header(h))
      headers[h] = req.header(h)
  }
  return headers
}


function createIssues(req, res) {
  // Look at the "fail %" header to increase chance of failure
  // Failures cascade, so this number shouldn't be set too high (under 0.3 is good)
  const failPercent = Number(req.header('fail')) || 0
  console.log(`failPercent: ${failPercent}`)
  if (Math.random() < failPercent) {
    res.status(500).end()
  }
}

var server = app.listen(app.get('port'), function () {

    var host = server.address().address
    var port = server.address().port

    console.log("Example app listening at http://%s:%s", host, port)

})


