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
