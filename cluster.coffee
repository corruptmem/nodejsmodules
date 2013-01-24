cluster = require('cluster')

children = 4
exiting = false

if cluster.isMaster
  recycle = () =>
    for workerId of cluster.workers
      worker = cluster.workers[workerId]
      worker.send('shutdown')
  
  term = () =>
    console.log("master got SIGTERM - terminating workers then exiting.")
    exiting = true
    recycle()

  process.on 'SIGTERM', term
  process.on 'SIGINT', term
  
  process.on 'SIGHUP', =>
    console.log("master got SIGHUP - recycling workers")
    recycle()

  console.log("master #{process.pid} is online")
  for s in [1..children]
    cluster.fork()

  cluster.on 'exit', (worker, code, signal) =>
    if not exiting
      console.error("worker #{worker.process.pid} died: #{code}, #{signal}")
      setTimeout (=> cluster.fork()), 2000
else
  console.log("worker #{process.pid} is online")
  require('./server')
