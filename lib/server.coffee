express = require("express")
http    = require("http")
path    = require("path")
fs      = require("fs")
hbs     = require("hbs")
glob    = require("glob")
coffee  = require("coffee-script")

app         = express()

## all environments
app.set 'port', "3000"

## set the eclectus config from the eclectus.json file
app.set "eclectus", JSON.parse(fs.readFileSync("eclectus.json", encoding: "utf8")).eclectus

## set the locals up here so we dont have to process them on every request
{ testFiles, testFolder } = app.get("eclectus")

testFiles = new RegExp(testFiles)

app.set "view engine", "html"
app.engine "html", hbs.__express

app.use require("compression")()
app.use require("morgan")(format: "dev")
app.use require("body-parser")()
app.use require("method-override")()

getFiles = (pattern) ->
  glob.sync pattern

getStylesheets = ->
  app.get("eclectus").stylesheets

getSpec = (spec) ->
  file = fs.readFileSync(spec, "utf8")

  return coffee.compile(file) if path.extname(spec) is ".coffee"

  return file

# getSpecs = (spec) ->
  ## grab all the files from our test folder
  # _(files).filter (file) -> testFiles.match file
  # files = getFiles("#{testFolder}/**/#{spec}")

## routing for the actual specs which are processed automatically
## this could be just a regular .js file or a .coffee file
app.get "/specs/:spec", (req, res) ->
  res.type "js"
  res.send getSpec "tests/#{req.params.spec}.coffee"

## routing for the dynamic iframe html
app.get "/iframe/:test", (req, res) ->

  ## renders the testHtml file defined in the config
  res.render path.join(process.cwd(), app.get("eclectus").testHtml), {
    title:        req.params.test
    stylesheets:  getStylesheets()
    utilities:    getUtilities()
    specs:        req.params.test
  }

## serve static file from public
app.use express.static(__dirname + "/public")

## errorhandler
app.use require("errorhandler")()

http.createServer(app).listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')

console.log(process.cwd())
console.log(__dirname)