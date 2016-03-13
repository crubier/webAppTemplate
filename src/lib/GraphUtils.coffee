
#Tarjan's strongly connected components algorithm
stronglyConnectedComponents = (G) ->
  index = 0
  R = [] #Result
  S = [] #Stack
  V = G.vertices
  E = G.edges
  indexmap = {}
  lowlinkmap = {}
  strongConnect = (v) ->
    #Set the depth index for v to the smallest unused index
    indexmap[v] = index
    lowlinkmap[v] = index
    index = index + 1
    S.push v
    # Consider successors of v
    for [v1, v2] in E when v1==v
      if not indexmap[v2]?
        #Successor w has not yet been visited; recurse on it
        strongConnect(v2)
        lowlinkmap[v1]  = Math.min(lowlinkmap[v1], lowlinkmap[v2])
      else if (v2 in S)
        #Successor w is in stack S and hence in the current SCC
        lowlinkmap[v1]  = Math.min(lowlinkmap[v1], indexmap[v2])
    # If v is a root node, pop the stack and generate an SCC
    if (lowlinkmap[v] == indexmap[v])
      #start a new strongly connected component
      scc = []
      loop
        w = S.pop()
        scc.push w
        break if w == v
      R.push scc
  #Higher level loop
  for vertex in V
    if not indexmap[vertex]?
      strongConnect(vertex)
  #return result
  R

# Cycles of a graph = strongly connected components with a difference
# for single node cycles
cycles = (G) ->
  scc for scc in stronglyConnectedComponents(G) when (
    scc.length>1 or ([scc[0],scc[0]] in G.edges)
  )

predecessor = (G,vertex) ->
  (edge[0] for edge in G.edges when edge[1]==vertex)

successor = (G,vertex) ->
  (edge[1] for edge in G.edges when edge[0]==vertex)

#Out degree of a vertex in a graph
outDegree = (G,vertex) ->
  successor(G,vertex).length

#In degree of a vertex in a graph
inDegree = (G,vertex) ->
  predecessor(G,vertex).length

#Sources of a graph are nodes with no predecessor
sources = (G) ->
  (vertex for vertex in G.vertices when inDegree(G,vertex) ==0)

#Sinks of a graph are nodes with no successor
sinks = (G) ->
  (vertex for vertex in G.vertices when outDegree(G,vertex) ==0)

#Exports
exports.stronglyConnectedComponents = stronglyConnectedComponents
exports.cycles = cycles
exports.predecessor = predecessor
exports.successor = successor
exports.outDegree = outDegree
exports.inDegree = inDegree
exports.sources = sources
exports.sinks = sinks


# test =
#   vertices:['A','B','C','D','E','F','G','H','in','out']
#   edges:[['in','A'],['A','out'],['A','E'],['B','A'],['C','B'],['C','D'],
#       ['D','C'],['E','B'],['F','B'],['F','E'],['F','G'],['G','C'],
#       ['G','F'],['H','D'],['H','G'],['H','H']]
# console.log cycles test
# #[ [ 'B', 'E', 'A' ], [ 'D', 'C' ], [ 'G', 'F' ] ]
# console.log stronglyConnectedComponents test
# ###
# [ [ 'out' ],
#   [ 'B', 'E', 'A' ],
#   [ 'D', 'C' ],
#   [ 'G', 'F' ],
#   [ 'H' ],
#   [ 'in' ] ]
#   ###
# console.log sources test
# #[ 'in' ]
# console.log sinks test
# #[ 'out' ]
# ## components = [['A','B','E'],['C','D'],['F','G'],['H']]