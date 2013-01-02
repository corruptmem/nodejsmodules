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


gompertz = (max, xdisp, growth, x) -> max * Math.exp(-xdisp*Math.exp(-growth * x))
sigmoid = (max, growth, x) -> max * ((2/(1+Math.exp(-growth*2*x)))-1)

rescale = (val, growth) -> sigmoid(100, growth, val)

metrics = [
  "depGithubInterest"
  "depGithubFreshness"
  "depNpmFreshness"
  "depNpmFrequency"
  "depNpmMaturity"
  "depNpmNewness"
  "depNpmInterest"
  "githubInterest"
  "githubFreshness"
  "npmFreshness"
  "npmMaturity"
  "npmInterest"
  "npmNewness"
  "npmFrequency"
]

ghQuery = [
    { "$match":  {"github.owner": {"$exists": true, "$ne": null }, "github.exists": true}}
    { "$project": {"github.owner": 1, "metrics": 1}}
    { "$group": {
      "_id": "$github.owner"
      "count": {"$sum": 1}
    } }
  ]
  
npmQuery = [
    { "$match":  {"owner": {"$exists": true, "$ne": null }}}
    { "$project": {"owner": 1, "metrics": 1}}
    { "$group": {
      "_id": "$owner"
      "count": {"$sum": 1}
    } }
  ]

for metric in metrics
  ghQuery[2]["$group"][metric] = {"$sum": "$metrics.#{metric}"}
  npmQuery[2]["$group"][metric] = {"$sum": "$metrics.#{metric}"}

updateAll = (selector, prefix, doc, cb) =>
  query = {}
  update = {"$set":{}}
  query[selector] = doc._id
  update["$set"]["metrics." + prefix + "Total"] = doc.count

  for metric in metrics
    update["$set"]["metrics." + prefix + metric[0].toUpperCase() + metric[1..]] = rescale(doc[metric], 0.001)

  NpmPackage.update(query, update, {"multi": true}, cb)


waiting = 0
exitIfDone = (error) =>
  if error?
    console.error(error)

  waiting -= 1
  if waiting == 0
    mongoose.connection.close()

NpmPackage.aggregate(npmQuery, (err, docs) =>
  if err?
    console.log(err)
    process.exit()

  i = 0
  for doc in docs
    console.log("Processing #{i} / #{docs.length} (pass 1)...")
    updateAll("owner", "author", doc, exitIfDone)
    waiting += 1
    i += 1
)

NpmPackage.aggregate(ghQuery, (err, docs) =>
  if err?
    console.log(err)
    process.exit()

  i = 0
  for doc in docs
    console.log("Processing #{i} / #{docs.length} (pass 2)...")
    updateAll("github.owner", "ghOwner", doc, exitIfDone)
    waiting += 1
    i += 1
)
