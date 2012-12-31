url = require('url')
request = require('request')
logger = require('winston')
NpmPackage = require('../model/NpmPackage')

class NpmIndexer
  registryUrl = "http://registry.npmjs.org"
  listUrl = "/-/short"
  
  constructor: () ->
   
  getList: (callback) ->
    requestUrl = url.resolve(registryUrl, listUrl)
    request.get(requestUrl, (error, response, body) ->
      return callback(error) if error?
      list = JSON.parse(body)
      callback(null, list))

  download: (packageId, callback) =>
    logger.info("Downloading " + packageId)
    requestUrl = url.resolve(registryUrl, packageId)
    request.get(requestUrl, (error, response, body) =>
      (return callback(error)) if error?
      callback(null, JSON.parse(body)))

  convertToModel: (json) ->
    obj = {
      id: json.name
    }
    
    obj.description = json.description if json.description?
    obj.author = json.author if json.author?
    obj.lastIndexed = new Date()

    latestVersionNumber = json?["dist-tags"]?.latest

    if latestVersionNumber?
      latestVersion = json.versions[latestVersionNumber]
      url = latestVersion.url ? latestVersion.homepage
      obj.url = url if url?
      obj.keywords = latestVersion.keywords ? []
      obj.repository = latestVersion.repository if latestVersion.repository?
      obj.dependencies = if latestVersion.dependencies? then Object.keys(latestVersion.dependencies) else []
      obj.devDependencies = if latestVersion.devDependencies? then Object.keys(latestVersion.devDependencies) else []
      obj.latestVersion = latestVersionNumber

    obj.versions = ({id: key, time: new Date(val)} for key, val of json.time)
    
    return obj

  indexPackage: (packageId, callback) =>
    logger.info("Indexing " + packageId)
    @download(packageId, (error, item) =>
      return callback(error) if error?
      obj = @convertToModel(item)
      logger.info("Saving " + packageId + " to database")
      NpmPackage.update({id: obj.id}, obj, { upsert: true }, callback))

  indexAll: (callback) =>
    @getList((error, list) =>
      return callback(error) if error?
      for id in list
        pending = list.length
        @indexPackage(id, (error) =>
          if error
            logger.error("Error indexing " + id, error)

          pending -= 1
          if pending == 0
            callback()))

module.exports = NpmIndexer
