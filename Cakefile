{exec} = require 'child_process'
task 'build', 'Build project from coffee to js and put in out/ dir', ->
  exec 'coffee --compile --output out/ *.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'coffee --compile --output out/app app', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'coffee --compile --output out/helpers helpers', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'coffee --compile --output out/model model', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'coffee --compile --output out/indexer indexer', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'cp -r public/ out/public', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'cp -r assets/ out/assets', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
