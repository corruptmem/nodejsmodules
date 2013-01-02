url = require('url')
request = require('request')
logger = require('winston')
NpmPackage = require('../model/NpmPackage')

class NpmIndexer
  registryUrl = "http://registry.npmjs.org"
  listUrl = "/-/short"
  downloadsUrl = "http://isaacs.iriscouch.com/downloads/_design/app/_view/pkg?group_level=2"
  
  constructor: () ->
   
  getList: (callback) ->
    requestUrl = url.resolve(registryUrl, listUrl)
    request.get(requestUrl, (error, response, body) ->
      return callback(error) if error?
      list = JSON.parse(body)
      callback(null, list))

  download: (packageId, callback) =>
    logger.info("Downloading " + packageId)
    pkgRequestUrl = url.resolve(registryUrl, packageId)
    startKeyJson = JSON.stringify([packageId])
    endKeyJson = JSON.stringify([packageId, {}])
    downloadRequestUrl = downloadsUrl + "&start_key=" + startKeyJson + "&end_key=" + endKeyJson

    pkg = null
    downloads = null
    called = false

    callbackIfDone = () =>
      if pkg? and downloads? and not called
        called = true
        callback(null, pkg, downloads)

    request.get(pkgRequestUrl, (error, response, body) =>
      if error? and not called
        called = true
        return callback(error)
      
      pkg = JSON.parse(body)
      callbackIfDone()
    )
    
    request.get(downloadRequestUrl, (error, response, body) =>
      if error? and not called
        called = true
        return callback(error)

      downloads = JSON.parse(body)
      callbackIfDone()
    )

  convertToModel: (json, downloads) ->
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

      if latestVersion.repository?
        obj.repository = latestVersion.repository
      else if latestVersion.repositories?.length? and latestVersion.repositories.length >= 1
        obj.repository = latestVersion.repositories[0]

      obj.repository = latestVersion.repository if latestVersion.repository?
      obj.dependencies = if latestVersion.dependencies? then Object.keys(latestVersion.dependencies) else []
      obj.devDependencies = if latestVersion.devDependencies? then Object.keys(latestVersion.devDependencies) else []
      obj.latestVersion = latestVersionNumber

      if latestVersion._npmUser?.email?
        obj.owner = latestVersion._npmUser.email
      else if latestVersion.maintainers?.length? >= 1 and latestVersion.maintainers[0].email?
        obj.owner = latestVersion.maintainers[0].email
      else if latestVersion.author?.email?
        obj.owner = latestVersion.author.email
      else if json.author?.email?
        obj.owner = json.author.email

    obj.versions = ({id: key, time: new Date(val)} for key, val of json.time)

    obj.downloads = {
      total: 0
      month: 0
    }

    monthAgo = new Date(obj.lastIndexed)
    monthAgo.setMonth(monthAgo.getMonth()-1)

    for dl in downloads.rows
      obj.downloads.total += dl.value
      if new Date(dl.key[1]) >= monthAgo
        obj.downloads.month += dl.value
    
    return obj

  indexPackage: (packageId, callback) =>
    logger.info("Indexing " + packageId)
    @download(packageId, (error, item, downloads) =>
      return callback(error) if error?
      obj = @convertToModel(item, downloads)
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
