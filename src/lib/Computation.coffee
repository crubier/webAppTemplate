Graph = require './GraphUtils.coffee'
ArrayUtils = require './ArrayUtils.coffee'

#get names of parameters of a function
getParamNames = (func) ->
  #Strip comments
  fnStr = func.toString().replace(/((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg, '')
  #Match arguments names
  fnStr.slice(fnStr.indexOf('(')+1, fnStr.indexOf(')')).match(/([^\s,]+)/g) ? []

#Create dependency graph for a computation
createGraph = (computations) ->
  vertices:ArrayUtils.union(
    (v for v of computations),
    (ArrayUtils.flatten(
      (p for p in getParamNames(computations[v])) for v of computations)
    )
  )
  edges:ArrayUtils.flatten(
    ([p,v] for p in getParamNames(computations[v])) for v of computations
  )
  
# Check if a computation is valid
computationIsValid = (computationgraph) ->
  Graph.cycles(computationgraph).length == 0

# Check if a computation is feasible with given inputs
missingInputs = (computationgraph,inputs) ->
  elem for elem in Graph.sources(computationgraph) when not(elem in inputs)

# Compute a coomputation bundle, with given input values
compute =(computations,inputs) ->
  graph = createGraph(computations)
  if not computationIsValid(graph)
    throw Error "Invalid computation graph"
  if missingInputs(
    graph,key for key of (if inputs? then inputs else {})).length > 0
    throw Error(
      "Missing input for computation : #{
        missingInputs(graph,key for key of (inputs?{}))
      }"
    )
  result = inputs
  done = (key for key of result)
  tobedone = ArrayUtils.exclusion((key for key of computations),done)
  while(tobedone.length >0) feasible = (elem for elem in tobedone when(
    ArrayUtils.isIncluded(done,Graph.predecessor(graph,elem)))
  )
    for elem in feasible
      paramValues = (getParamNames computations[elem])
        .map (paramName)->result[paramName]
      result[elem] = computations[elem].apply(null,paramValues)
    done= (key for key of result)
    tobedone = ArrayUtils.exclusion(tobedone,done)
  result



exports.computationIsValid = computationIsValid
exports.compute=compute

# console.log JSON.stringify createGraph computings
# console.log JSON.stringify Graph.cycles createGraph computings
# console.log JSON.stringify Graph.sources createGraph computings
# console.log JSON.stringify Graph.sinks createGraph computings
# console.log computationIsValid computings