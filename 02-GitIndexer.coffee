require('js-yaml')
mongoose = require('mongoose')
url = require('url')
request = require('request')
logger = require('winston')
NpmPackage = require('./model/NpmPackage')
config = require('./config')

class GitIndexer
  api_url = "https://corruptmem:bB4ndgUH5C@api.github.com/repos/"

  getReposFromUrl: (repos_url) ->
    if not repos_url?
      return null

    repos_url = repos_url.replace(".com:", ".com/") # for git-style URLs like git@github.com:a/b.git

    parsed = url.parse(repos_url)
    
    if not parsed.path?
      return null

    split = parsed.path.split('/')
    
    if split.length < 3
      return null

    author = split[1]
    repos = split[2]

    if repos.substr(-4) == ".git"
      repos = repos.substr(0, repos.length-4)

    return { author: author, repos: repos }

  download: (repos, user, callback) =>
    logger.info("Downloading github: #{repos} #{user}")
    requestUrl = url.resolve(api_url, "#{user}/#{repos}")
    logger.info("URL #{requestUrl}")
    request.get(requestUrl, (error, response, body) =>
      (return callback(error)) if error?
      try
        parsed = JSON.parse(body)
      catch err
        console.log(body)
        console.log(error)
        return callback(err)
      callback(null, parsed))

  fill: (doc, callback) =>
    gh = @getReposFromUrl(doc.repository.url)
    logger.error(new Error("Could not parse repository URL for " + doc.id))

    @download(gh?.repos, gh?.author, (error, ghdata) =>
      logger.error(error) if error?
      if not error?
        logger.error("Error loading #{doc.id}: #{ghdata.message}") if ghdata.message?

      if error? or ghdata?.message?
        doc.github = { exists: false, lastIndexed: new Date() }
      else
        doc.github = {
          exists: true,
          stars: ghdata.watchers_count,
          forks: ghdata.forks_count,
          openIssues: ghdata.open_issues_count,
          network: ghdata.network_count,
          lastPush: new Date(ghdata.pushed_at),
          size: ghdata.size,
          homepage: ghdata.homepage,
          fork: ghdata.fork,
          hasIssues: ghdata.has_issues,
          url: ghdata.url,
          langauge: ghdata.language,
          created: new Date(ghdata.created_at),
          owner: ghdata.owner?.login,
          description: ghdata.description,
          lastIndexed: new Date()
        }

      doc.save(callback)
    )

  fillAll: (callback) =>
    NpmPackage.find({"repository.type": "git"}).sort({"github.lastIndexed": 1}).limit(1000).exec((err, docs) =>
      if err?
        return callback(err)
      pending = docs.length
      for doc in docs
        ((doc) =>
          logger.info("Looking up info for #{doc.id}")
          @fill(doc, (error) =>
            if error?
              logger.error("Error retreiving git data for #{doc.id}")
              logger.error(error)
            else
              logger.info("Done #{doc.id}")
            pending -= 1
            if pending == 0
              callback()
          )
        )(doc)
    )


mongodb = mongoose.connect(config.mongodb)
gi = new GitIndexer()
gi.fillAll((err) =>
  console.log(err) if err?
  mongoose.connection.close())
