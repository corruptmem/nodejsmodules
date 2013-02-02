mongoose = require('mongoose')
schema = mongoose.Schema({
  id: String,
  description: String,
  keywords: [ String ],
  normalisedKeywords: [ String ],
  latestVersion: String,
  url: String,
  repository: {
    type: { type: String },
    url: String
  },
  author: { name: String, email: String },
  owner: String, # email for NPM owner
  dependencies: [ String ],
  devDependencies: [ String ],
  versions: [ {id: String, time: Date} ]
  reverseDependencies: [ {id: String, distance: Number} ]
  lastIndexed: Date
  downloads: {
    total: Number
    month: Number
  }
  metrics: {
    # pass 1
    githubInterest: Number
    githubFreshness: Number
    npmFreshness: Number
    npmNewness: Number
    npmMaturity: Number
    npmFrequency: Number
    npmInterest: Number

    # pass 2
    depGithubInterest: Number
    depGithubFreshness: Number
    depNpmFreshness: Number
    depNpmMaturity: Number
    depNpmNewness: Number
    depNpmFrequency: Number
    depNpmInterest: Number
    
    # pass 3
    authorTotal: Number
    authorGithubInterest: Number
    authorGithubFreshness: Number
    authorNpmFreshness: Number
    authorNpmNewness: Number
    authorNpmMaturity: Number
    authorNpmFrequency: Number
    authorNpmInterest: Number
    authorDepGithubInterest: Number
    authorDepGithubFreshness: Number
    authorDepNpmFreshness: Number
    authorDepNpmMaturity: Number
    authorDepNpmNewness: Number
    authorDepNpmFrequency: Number
    authorDepNpmInterest: Number
    
    ghOwnerTotal: Number
    ghOwnerGithubInterest: Number
    ghOwnerGithubFreshness: Number
    ghOwnerNpmFreshness: Number
    ghOwnerNpmNewness: Number
    ghOwnerNpmMaturity: Number
    ghOwnerNpmFrequency: Number
    ghOwnerNpmInterest: Number
    ghOwnerDepGithubInterest: Number
    ghOwnerDepGithubFreshness: Number
    ghOwnerDepNpmFreshness: Number
    ghOwnerDepNpmMaturity: Number
    ghOwnerDepNpmNewness: Number
    ghOwnerDepNpmFrequency: Number
    ghOwnerDepNpmInterest: Number

    # pass 3
    popularScore: Number
    interestingScore: Number
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

schema.index({"id": 1}, {unique: true})
schema.index({"owner": 1})
schema.index({"keywords": 1})
schema.index({"normalisedKeywords": 1})
schema.index({"metrics.newScore": 1})
schema.index({"metrics.interestingScore": 1})
schema.index({"metrics.popularScore": 1})

module.exports = mongoose.model('NpmPackage', schema)
