# This is somewhat counter to Meteor logic - these calls simply translate corresponding signatures and call methods
# on the server, returning results in the callback (error, result) function
# So, on one hand, aggregation framework is supposed to be (?) read-only, so it's ok that we expose all these methods
# as the client cannot alter db (?). BUT - we still expose ALL data to the client in this way, so:
# TODO some form of access control is needed.

if Meteor.isClient

  _.extend Meteor.Collection::,

    distinct: (key, callback) ->
      Meteor.apply "_callAdvancedDBMethod", [@_name, "distinct", key], {wait:false, onResultReceived: callback}

    aggregate: (pipeline, callback) ->
      Meteor.apply "_callAdvancedDBMethod", [@_name, "aggregate", pipeline], {wait:false, onResultReceived: callback}

    mapReduce1: (map, reduce, options, callback) ->
      Meteor.apply "_callAdvancedDBMethod", [@_name, "mapReduce", [map, reduce, options]], {wait:false, onResultReceived: callback}

    mapReduce: (map, reduce, options, callback)->
      Meteor.apply "_callMapReduce", [@_name, map, reduce, options], {wait:false, onResultReceived: callback}