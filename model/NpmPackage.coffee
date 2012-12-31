mongoose = require('mongoose')
schema = mongoose.Schema({
  id: String,
  description: String,
  keywords: [ String ],
  latestVersion: String,
  url: String,
  repository: {
    type: { type: String },
    url: String
  },
  author: { name: String, email: String },
  dependencies: [ String ],
  devDependencies: [ String ],
  versions: [ {id: String, time: Date} ]
  reverseDependencies: [ {id: String, distance: Number} ]
  lastIndexed: Date,
  metrics: {
    # pass 1
    githubInterest: Number
    githubFreshness: Number
    npmFreshness: Number
    npmNewness: Number
    npmMaturity: Number
    npmFrequency: Number

    # pass 2
    depGithubInterest: Number
    depGithubFreshness: Number
    depNpmFreshness: Number
    depNpmMaturity: Number
    depNpmNewness: Number
    depNpmFrequency: Number

    # pass 3
    popularScore: Number
    interestingScore: Number

    # pass 4
    githubAuthorScore: Number
    newScore: Number

  }
  github: {
    stars: Number,
    forks: Number,
    openIssues: Number,
    network: Number,
    lastPush: Date,
    homepage: String,
    size: Number,
    fork: Boolean,
    hasIssues: Boolean,
    url: String,
    language: String,
    created: Date,
    owner: String,
    description: String,
    lastIndexed: Date,
    exists: Boolean
  }
})

module.exports = mongoose.model('NpmPackage', schema)
