require('js-yaml')
mongoose = require('mongoose')
url = require('url')
request = require('request')
logger = require('winston')
_ = require('underscore')
NpmPackage = require('./model/NpmPackage')
config = require('./config')

mongoose.connect(config.mongodb)

# metrics {
# gompertz(max, xdisp, growth, x) = max*e^(-xdisp*e^(-growth*x))
# sigmoid(max, growth, x) = max*((2/(1+e^(-growth*2*x)))-1)
# githubInterest: sigmoid(25, 0.01, stars) + sigmoid(75, 0.01, forks)
# githubFreshness: max - gompertz(max, xdisp, decay, days(ghLastIndexed - lastPush)) # max: 100, decay: 0.01, xdisp: 5
# npmFreshness: max - gompertz(max, xdisp, decay, days(npmLastIndexed - lastVersion)) # max: 100, decay: 0.01, xdisp: 5
# npmNewness: max - npmMaturity # max: 100, decay: 0.01, xdisp: 5
# npmMaturity: gompertz(max, xdisp, decay, days(npmLastIndexed - firstVersion)) # max: 100, decay: 0.01, xdisp: 5 
# npmFrequency: gompertz(max, xdisp, decay, commitsPerYearBetween(npmLastIndexed, firstCommit) # max 100, decay: 0.15, xdisp: 6
#
# authorScore: sum
#
# interest: more weighted to forks, stars, newness, etc. than revdeps
# popular: more weighted to revdeps than forks, stars, newness, etc.
# new: more weighted to newness, freshness, author score


gompertz = (max, xdisp, growth, x) -> max * Math.exp(-xdisp*Math.exp(-growth * x))
sigmoid = (max, growth, x) -> max * ((2/(1+Math.exp(-growth*2*x)))-1)

rescale = (val, growth) -> sigmoid(100, growth, val)

waiting = 1

exitIfDone = (error) =>
  if error
    console.error(error)
  waiting -= 1
  if(waiting == 0)
    console.log("Closing.")
    mongoose.connection.close()

metrics = ["githubInterest", "githubFreshness", "npmFreshness", "npmMaturity", "npmNewness", "npmFrequency"]
growth = {
  "depGithubInterest": 0.0001,
  "depGithubFreshness": 0.00001,
  "depNpmFreshness": 0.00001,
  "depNpmMaturity": 0.00001,
  "depNpmNewness": 0.00001,
  "depNpmFrequency": 0.00001,
}
depMetrics = ("dep" + metric[0].toUpperCase() + metric[1..] for metric in metrics)

stream = NpmPackage.find().sort({"$natural": -1}).stream()
stream.on('data', (doc) =>
  console.log("Processing #{doc.id} (waiting #{waiting})...")

  rdeps = {}
  for rdep in doc.reverseDependencies
    rdeps[rdep.id] = rdep

  for depMetric in depMetrics
    doc.metrics[depMetric] = 0

  NpmPackage.find({"id": {"$in": (rdep.id for rdep in doc.reverseDependencies)}}, {"id": 1, "metrics": 1}).exec((err, rdocs) =>
    for rdoc in rdocs
      ratio = 1/Math.pow(rdeps[rdoc.id].distance,2)
      for metric, n in metrics
        depMetric = depMetrics[n]
        doc.metrics[depMetric] += rdoc.metrics[metric] * ratio unless isNaN(rdoc.metrics[metric])

    for depMetric in depMetrics
      doc.metrics[depMetric] = rescale(doc.metrics[depMetric], growth[depMetric])

    doc.save(() =>
      exitIfDone())
  )

  waiting += 1
)

stream.on('error', (error) =>
  console.log(error)
  process.exit()
)

stream.on('close', exitIfDone)
