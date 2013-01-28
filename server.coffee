require 'js-yaml'
express = require 'express'
mongoose = require 'mongoose'
expressParams = require 'express-params'

config = require './config'

app = express()
app.set 'views', __dirname + '/app/views'
app.set 'view engine', 'jade'

app.locals(require './helpers/links')

expressParams.extend(app)

app.configure =>
  app.use express.bodyParser()
  app.use express.methodOverride()

app.configure 'production', =>
  app.use (req, res, next) =>
    res.setHeader("Cache-Control", "public, max-age=345600")
    res.setHeader("Expires", new Date(Date.now() + 345600000).toUTCString())
    console.log(req.url)
    next()

app.configure =>
  app.use app.router

app.configure 'development', =>
  app.use express.static __dirname + "/public"
  app.use require('connect-assets')
  app.use express.errorHandler {
    dumpExceptions: true
    showStack: true
  }

app.configure 'production', =>
  servePath = "https://d1g0cckr7vxu10.cloudfront.net"
  app.use(require('connect-assets') { buildDir: "public", servePath: servePath })
  app.use express.errorHandler()

for controller in ["home", "tags"]
  require("./app/controllers/#{controller}").setup(app)

# process management
server = null
mongoose.connect(config.mongodb)
mongoose.connection.once 'open', =>
  server = app.listen config.web.port, =>
    process.send('online') if process.send?

quit = =>
  console.log "worker #{process.pid}: terminating gracefully"
  if server?
    server.close =>
      console.log "worker #{process.pid}: server closed"
      mongoose.disconnect () =>
        console.log("worker #{process.pid}: mongoose disconnected; terminating process")
        process.exit(0)
  else
    process.exit(0)

process.on 'message', (message) => quit() if message == 'shutdown'
process.on 'SIGTERM', quit
process.on 'SIGINT', quit
