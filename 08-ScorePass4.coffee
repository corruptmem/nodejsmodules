require('js-yaml')
mongoose = require('mongoose')
url = require('url')
request = require('request')
logger = require('winston')
_ = require('underscore')
NpmPackage = require('./model/NpmPackage')
config = require('./config')

mongoose.connect(config.mongodb)

waiting = 1
exitIfDone = (err) =>
  console.log(err) if err?
  waiting -= 1
  if waiting <= 0
    console.log("Done")
    process.exit()

stream = NpmPackage.find({}).stream()
stream.on('error', (err) =>
  console.error(err)
  process.exit()
)

stream.on('close', () =>
  console.log("Iteration done")
  exitIfDone()
)

stream.on('data', (doc) =>
  console.log("Processing #{doc.id}")
  zero(doc)

  doc.metrics.popularScore =
    (
      doc.metrics.githubInterest +
      doc.metrics.npmInterest +
      doc.metrics.depGithubInterest +
      doc.metrics.depNpmInterest
    ) / 4

  doc.metrics.interestingScore =
    (
      doc.metrics.githubInterest +
      doc.metrics.npmInterest / 2 +
      doc.metrics.npmFrequency / 4 +
      doc.metrics.npmFreshness / 2 +
      doc.metrics.githubFreshness / 4 +
      doc.metrics.authorGithubInterest / 64 +
      doc.metrics.authorNpmInterest / 64 +
      doc.metrics.authorDepGithubInterest / 64 +
      doc.metrics.authorDepNpmInterest / 64 +
      doc.metrics.ghOwnerGithubInterest / 64 +
      doc.metrics.ghOwnerNpmInterest / 64 +
      doc.metrics.ghOwnerDepGithubInterest / 64 +
      doc.metrics.ghOwnerDepNpmInterest / 64
    ) / 2.625

  doc.metrics.newScore =
    (
      doc.metrics.npmFreshness / 2 +
      doc.metrics.npmNewness +
      doc.metrics.githubFreshness / 2 +
      doc.metrics.authorGithubInterest / 64 +
      doc.metrics.authorNpmInterest / 64 +
      doc.metrics.authorDepGithubInterest / 64 +
      doc.metrics.authorDepNpmInterest / 64 +
      doc.metrics.ghOwnerGithubInterest / 64 +
      doc.metrics.ghOwnerNpmInterest / 64 +
      doc.metrics.ghOwnerDepGithubInterest / 64 +
      doc.metrics.ghOwnerDepNpmInterest / 64 +
      doc.metrics.githubInterest / 4 +
      doc.metrics.npmInterest / 4 +
      doc.metrics.depGithubInterest / 4 +
      doc.metrics.depNpmInterest / 4
    ) / 3.125

  console.log("Scores for #{doc.id}: popular = #{doc.metrics.popularScore}, interesting = #{doc.metrics.interestingScore}, new = #{doc.metrics.newScore}")
    
  waiting += 1
  doc.save((err) =>
    console.log("Saved #{doc.id} - waiting #{waiting}")
    exitIfDone(err)
  )
)


zero = (doc) =>
  doc.metrics.githubInterest = 0 unless doc.metrics.githubInterest?
  doc.metrics.githubFreshness = 0 unless doc.metrics.githubFreshness?
  doc.metrics.npmFreshness = 0 unless doc.metrics.npmFreshness?
  doc.metrics.npmNewness = 0 unless doc.metrics.npmNewness?
  doc.metrics.npmMaturity = 0 unless doc.metrics.npmMaturity?
  doc.metrics.npmFrequency = 0 unless doc.metrics.npmFrequency?
  doc.metrics.npmInterest = 0 unless doc.metrics.npmInterest?
  doc.metrics.depGithubInterest = 0 unless doc.metrics.depGithubInterest?
  doc.metrics.depGithubFreshness = 0 unless doc.metrics.depGithubFreshness?
  doc.metrics.depNpmFreshness = 0 unless doc.metrics.depNpmFreshness?
  doc.metrics.depNpmMaturity = 0 unless doc.metrics.depNpmMaturity?
  doc.metrics.depNpmNewness = 0 unless doc.metrics.depNpmNewness?
  doc.metrics.depNpmFrequency = 0 unless doc.metrics.depNpmFrequency?
  doc.metrics.depNpmInterest = 0 unless doc.metrics.depNpmInterest?
  doc.metrics.authorTotal = 0 unless doc.metrics.authorTotal?
  doc.metrics.authorGithubInterest = 0 unless doc.metrics.authorGithubInterest?
  doc.metrics.authorGithubFreshness = 0 unless doc.metrics.authorGithubFreshness?
  doc.metrics.authorNpmFreshness = 0 unless doc.metrics.authorNpmFreshness?
  doc.metrics.authorNpmNewness = 0 unless doc.metrics.authorNpmNewness?
  doc.metrics.authorNpmMaturity = 0 unless doc.metrics.authorNpmMaturity?
  doc.metrics.authorNpmFrequency = 0 unless doc.metrics.authorNpmFrequency?
  doc.metrics.authorNpmInterest = 0 unless doc.metrics.authorNpmInterest?
  doc.metrics.authorDepGithubInterest = 0 unless doc.metrics.authorDepGithubInterest?
  doc.metrics.authorDepGithubFreshness = 0 unless doc.metrics.authorDepGithubFreshness?
  doc.metrics.authorDepNpmFreshness = 0 unless doc.metrics.authorDepNpmFreshness?
  doc.metrics.authorDepNpmMaturity = 0 unless doc.metrics.authorDepNpmMaturity?
  doc.metrics.authorDepNpmNewness = 0 unless doc.metrics.authorDepNpmNewness?
  doc.metrics.authorDepNpmFrequency = 0 unless doc.metrics.authorDepNpmFrequency?
  doc.metrics.authorDepNpmInterest = 0 unless doc.metrics.authorDepNpmInterest?
  doc.metrics.ghOwnerTotal = 0 unless doc.metrics.ghOwnerTotal?
  doc.metrics.ghOwnerGithubInterest = 0 unless doc.metrics.ghOwnerGithubInterest?
  doc.metrics.ghOwnerGithubFreshness = 0 unless doc.metrics.ghOwnerGithubFreshness?
  doc.metrics.ghOwnerNpmFreshness = 0 unless doc.metrics.ghOwnerNpmFreshness?
  doc.metrics.ghOwnerNpmNewness = 0 unless doc.metrics.ghOwnerNpmNewness?
  doc.metrics.ghOwnerNpmMaturity = 0 unless doc.metrics.ghOwnerNpmMaturity?
  doc.metrics.ghOwnerNpmFrequency = 0 unless doc.metrics.ghOwnerNpmFrequency?
  doc.metrics.ghOwnerNpmInterest = 0 unless doc.metrics.ghOwnerNpmInterest?
  doc.metrics.ghOwnerDepGithubInterest = 0 unless doc.metrics.ghOwnerDepGithubInterest?
  doc.metrics.ghOwnerDepGithubFreshness = 0 unless doc.metrics.ghOwnerDepGithubFreshness?
  doc.metrics.ghOwnerDepNpmFreshness = 0 unless doc.metrics.ghOwnerDepNpmFreshness?
  doc.metrics.ghOwnerDepNpmMaturity = 0 unless doc.metrics.ghOwnerDepNpmMaturity?
  doc.metrics.ghOwnerDepNpmNewness = 0 unless doc.metrics.ghOwnerDepNpmNewness?
  doc.metrics.ghOwnerDepNpmFrequency = 0 unless doc.metrics.ghOwnerDepNpmFrequency?
  doc.metrics.ghOwnerDepNpmInterest = 0 unless doc.metrics.ghOwnerDepNpmInterest?
  doc.metrics.popularScore = 0 unless doc.metrics.popularScore?
  doc.metrics.interestingScore = 0 unless doc.metrics.interestingScore?
  doc.metrics.newScore = 0 unless doc.metrics.newScore?
