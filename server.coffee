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
    

  # exposing the methods to the client
  Meteor.methods
    _callAdvancedDBMethod: _futureWrapper

    # Not really DRY, but have to return slightly different results from mapReduce as mongo method returns
    # a mongo collection, which we don't need here at all
    _callMapReduce: (collection, map, reduce, options)->
      col = if (typeof collection) == "string" then  _dummyCollection_ else collection
      collectionName = if (typeof collection) == "string" then  collection else collection._name

      #tl?.debug "callMapReduce called for collection " + collectionName + " map: " + map + " reduce: " + reduce + " options: #{JSON.stringify(options)}"
      future = new Future
      col.find()._mongo.db.collection(collectionName,(err,coll)->
        future.throw err if err
        coll.mapReduce(map, reduce, options, (err,result,stats)->
          #tl?.debug "Inside MapReduce callback now!"
          future.throw(err) if err
          res = {collectionName: result.collectionName, stats: stats}
          future.ret([true,res])
        )
      )
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

    distinct: (key) ->
      #_collectionDistinct @_name, key, query, options
      _futureWrapper @_name, "distinct", key

    aggregate: (pipeline) ->
      _futureWrapper @_name, "aggregate", pipeline

    mapReduce: (map, reduce, options)->
      Meteor.apply "_callMapReduce", [@_name, map, reduce, options]



