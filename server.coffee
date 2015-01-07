tl = TLog?.getLogger()
#hacky advanced mongo definitions based on https://github.com/meteor/meteor/pull/644
if Meteor.isServer

  path = Npm.require("path")
  MongoDB = Npm.require("mongodb")
  Future = Npm.require(path.join("fibers", "future"))

  _dummyCollection_ = new Meteor.Collection '__dummy__'

  # Wrapper of the call to the db into a Future
  _futureWrapper = (collection, commandName, args)->
    col = if (typeof collection) == "string" then  _dummyCollection_ else collection
    collectionName = if (typeof collection) == "string" then  collection else collection._name

    #tl?.debug "future Wrapper called for collection " + collectionName + " command: " + commandName + " args: " + args
    
    coll1 = col.find()._mongo.db.collection(collectionName)

    future = new Future
    cb = future.resolver()
    coll1[commandName](args, cb)
    result = future.wait()

  # Wrapper of the call to the db into a Future for calls with queries like distinct
  _distinctFutureWrapper = (collection, commandName, query, args)->
    col = if (typeof collection) == "string" then  _dummyCollection_ else collection
    collectionName = if (typeof collection) == "string" then  collection else collection._name

    #tl?.debug "distinct Future Wrapper2 called for collection " + collectionName + " command: " + commandName + " query: "+JSON.stringify(query)+" args: " + JSON.stringify(args)
    
    coll1 = col.find()._mongo.db.collection(collectionName)

    future = new Future
    cb = future.resolver()
    coll1[commandName](args, query, cb)
    result = future.wait()
    

  # exposing the methods to the client
  Meteor.methods
    _callAdvancedDBMethod: _futureWrapper

    # Not really DRY, but have to return slightly different results from mapReduce as mongo method returns
    # a mongo collection, which we don't need here at all
    _callMapReduce: (collection, map, reduce, options)->
      col = if (typeof collection) == "string" then  _dummyCollection_ else collection
      collectionName = if (typeof collection) == "string" then  collection else collection._name

      tl?.debug "callMapReduce called for collection " + collectionName + " map: " + map + " reduce: " + reduce + " options: #{JSON.stringify(options)}"
      coll1 = col.find()._mongo.db.collection(collectionName)

      future = new Future
      #cb = future.resolver()
      coll1.mapReduce map, reduce, options, (err,result,stats)->
          #tl?.debug "Inside MapReduce callback now!"
          future.throw(err) if err
          res = {collectionName: result.collectionName, stats: stats}
          future.return [true,res]

      result = future.wait() #
      #console.log "Result from the callMapReduce is: "
      #console.dir result[1]
      throw result[1] if !result[0]

      if result[1].collectionName
        col = new Meteor.Collection result[1].collectionName
        Meteor.publish result[1].collectionName, ->
          col.find {"_id" : {$ne: ""}} # hack to allow Meteor fetching the values as apparently it does not support empty ids
      result[1]



  # Extending Collection on the server
  _.extend Meteor.Collection::,

    distinct: (key, query) ->
      #_collectionDistinct @_name, key, query, options
      _distinctFutureWrapper @_name, "distinct", query||{}, key

    aggregate: (pipeline) ->
      _futureWrapper @_name, "aggregate", pipeline

    mapReduce: (map, reduce, options)->
      Meteor.apply "_callMapReduce", [@_name, map, reduce, options]



