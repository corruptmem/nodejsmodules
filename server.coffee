require 'js-yaml'
express = require 'express'
stylus = require 'stylus'
nib = require 'nib'

config = require './config'

app = express()
app.set 'views', __dirname + 'app/views'
app.set 'view engine', 'jade'


app.configure =>
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use stylus.middleware {
    src: "#{__dirname}/app"
    dest: "#{__dirname}/public"
    compile: (str, path) =>
      stylus(str)
        .set('filename', path)
        .set('compress', false)
        .use(nib())
  }
  app.use express.static __dirname + "/public"

app.configure 'development', =>
  app.use express.errorHandler {
    dumpExceptions: true
    showStack: true
  }

app.configure 'production', =>
  app.use express.errorHandler()

for controller in ["home"]
  require("./app/controllers/#{controller}").setup(app)

app.listen config.web.port
