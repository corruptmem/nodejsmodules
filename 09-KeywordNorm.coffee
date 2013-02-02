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

exitIfDone = () =>
  waiting -= 1
  if(waiting == 0)
    mongoose.connection.close()

re = /\b[a-zA-Z][a-zA-Z0-9\-\.]{2,}\b/g

stream = NpmPackage.find().sort({"$natural": -1}).stream()
stream.on('data', (doc) =>
  console.log("Processing #{doc.id}...")

  doc.normalisedKeywords = []
  keyMap = {}
  if doc.keywords? and doc.keywords.length > 0
    for keyword in doc.keywords
      for match in keyword.match(re) ? []
        keyMap[match.toLowerCase()] = true

  if doc.description? and doc.description.length > 0
    for match in doc.description.match(re) ? []
      keyMap[match.toLowerCase()] = true

  for word in ['for', 'and', 'node.js', 'the', 'library', 'with', 'node', 'that', 'your', 'using', 'from', 'use', 'you', 'can', 'without']
    delete keyMap[word]

  for keyword of keyMap
    doc.normalisedKeywords.push(keyword)

  console.log(doc.normalisedKeywords)

  doc.save(exitIfDone)
  waiting += 1
)

stream.on('error', (error) =>
  console.log(error)
  process.exit()
)

stream.on('close', exitIfDone)
