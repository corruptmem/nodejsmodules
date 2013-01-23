require 'js-yaml'
express = require 'express'
mongoose = require 'mongoose'
expressParams = require 'express-params'

config = require './config'

mongoose.connect(config.mongodb)

app = express()
app.set 'views', __dirname + '/app/views'
app.set 'view engine', 'jade'

app.locals(require './helpers/links')

expressParams.extend(app)

app.configure =>
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router

app.configure 'development', =>
  app.use express.static __dirname + "/public"
  app.use(require('connect-assets')())
  app.use express.errorHandler {
    dumpExceptions: true
    showStack: true
  }

app.configure 'production', =>
  app.use(require('connect-assets') { buildDir: "public", servePath: "https://d1g0cckr7vxu10.cloudfront.net" })
  app.use express.errorHandler()

for controller in ["home", "tags"]
  require("./app/controllers/#{controller}").setup(app)

app.listen config.web.port
