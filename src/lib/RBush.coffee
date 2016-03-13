#https://github.com/mourner/rbush

rbush = (maxEntries, format) ->
  
  # jshint newcap: false, validthis: true
  return new rbush(maxEntries, format)  unless this instanceof rbush
  
  # max entries in a node is 9 by default; min node fill
  # is 40% for best performance
  @_maxEntries = Math.max(4, maxEntries or 9)
  @_minEntries = Math.max(2, Math.ceil(@_maxEntries * 0.4))
  @_initFormat format  if format
  @clear()
  return
rbush:: =
  all: ->
    @_all @data, []

  search: (bbox) ->
    node = @data
    result = []
    return result  unless @_intersects(bbox, node.bbox)
    nodesToSearch = []
    i = undefined
    len = undefined
    child = undefined
    childBBox = undefined
    while node
      i = 0
      len = node.children.length

      while i < len
        child = node.children[i]
        childBBox = (if node.leaf then @toBBox(child) else child.bbox)
        if @_intersects(bbox, childBBox)
          if node.leaf
            result.push child
          else if @_contains(bbox, childBBox)
            @_all child, result
          else
            nodesToSearch.push child
        i++
      node = nodesToSearch.pop()
    result

  load: (data) ->
    return this  unless data and data.length
    if data.length < @_minEntries
      i = 0
      len = data.length

      while i < len
        @insert data[i]
        i++
      return this
    
    # recursively build the tree with the given data
    # from stratch using OMT algorithm
    node = @_build(data.slice(), 0)
    unless @data.children.length
      
      # save as is if tree is empty
      @data = node
    else if @data.height is node.height
      
      # split root if trees have the same height
      @_splitRoot @data, node
    else
      if @data.height < node.height
        
        # swap trees if inserted one is bigger
        tmpNode = @data
        @data = node
        node = tmpNode
      
      # insert the small tree into the large tree at appropriate level
      @_insert node, @data.height - node.height - 1, true
    this

  insert: (item) ->
    @_insert item, @data.height - 1  if item
    this

  clear: ->
    @data =
      children: []
      leaf: true
      bbox: @_empty()
      height: 1

    this

  remove: (item) ->
    return this  unless item
    node = @data
    bbox = @toBBox(item)
    path = []
    indexes = []
    i = undefined
    parent = undefined
    index = undefined
    goingUp = undefined
    
    # depth-first iterative tree traversal
    while node or path.length
      unless node # go up
        node = path.pop()
        parent = path[path.length - 1]
        i = indexes.pop()
        goingUp = true
      if node.leaf # check current node
        index = node.children.indexOf(item)
        if index isnt -1
          
          # item found, remove the item and condense tree upwards
          node.children.splice index, 1
          path.push node
          @_condense path
          return this
      if not goingUp and not node.leaf and @_contains(node.bbox, bbox) # go down
        path.push node
        indexes.push i
        i = 0
        parent = node
        node = node.children[0]
      else if parent # go right
        i++
        node = parent.children[i]
        goingUp = false
      else # nothing found
        node = null
    this

  toBBox: (item) ->
    item

  compareMinX: (a, b) ->
    a[0] - b[0]

  compareMinY: (a, b) ->
    a[1] - b[1]

  toJSON: ->
    @data

  fromJSON: (data) ->
    @data = data
    this

  _all: (node, result) ->
    nodesToSearch = []
    while node
      if node.leaf
        result.push.apply result, node.children
      else
        nodesToSearch.push.apply nodesToSearch, node.children
      node = nodesToSearch.pop()
    result

  _build: (items, level, height) ->
    N = items.length
    M = @_maxEntries
    node = undefined
    if N <= M
      node =
        children: items
        leaf: true
        height: 1

      @_calcBBox node
      return node
    unless level
      
      # target height of the bulk-loaded tree
      height = Math.ceil(Math.log(N) / Math.log(M))
      
      # target number of root entries to maximize storage utilization
      M = Math.ceil(N / Math.pow(M, height - 1))
      items.sort @compareMinX
    
    # TODO eliminate recursion?
    node =
      children: []
      height: height

    N1 = Math.ceil(N / M) * Math.ceil(Math.sqrt(M))
    N2 = Math.ceil(N / M)
    compare = (if level % 2 is 1 then @compareMinX else @compareMinY)
    i = undefined
    j = undefined
    slice = undefined
    sliceLen = undefined
    childNode = undefined
    
    # split the items into M mostly square tiles
    i = 0
    while i < N
      slice = items.slice(i, i + N1).sort(compare)
      j = 0
      sliceLen = slice.length

      while j < sliceLen
        
        # pack each entry recursively
        childNode = @_build(slice.slice(j, j + N2), level + 1, height - 1)
        node.children.push childNode
        j += N2
      i += N1
    @_calcBBox node
    node

  _chooseSubtree: (bbox, node, level, path) ->
    i = undefined
    len = undefined
    child = undefined
    targetNode = undefined
    area = undefined
    enlargement = undefined
    minArea = undefined
    minEnlargement = undefined
    loop
      path.push node
      break  if node.leaf or path.length - 1 is level
      minArea = minEnlargement = Infinity
      i = 0
      len = node.children.length

      while i < len
        child = node.children[i]
        area = @_area(child.bbox)
        enlargement = @_enlargedArea(bbox, child.bbox) - area
        
        # choose entry with the least area enlargement
        if enlargement < minEnlargement
          minEnlargement = enlargement
          minArea = (if area < minArea then area else minArea)
          targetNode = child
        else if enlargement is minEnlargement
          
          # otherwise choose one with the smallest area
          if area < minArea
            minArea = area
            targetNode = child
        i++
      node = targetNode
    node

  _insert: (item, level, isNode) ->
    bbox = (if isNode then item.bbox else @toBBox(item))
    insertPath = []
    
    # find the best node for accommodating the item,
    # saving all nodes along the path too
    node = @_chooseSubtree(bbox, @data, level, insertPath)
    
    # put the item into the node
    node.children.push item
    @_extend node.bbox, bbox
    
    # split on node overflow; propagate upwards if necessary
    while level >= 0
      if insertPath[level].children.length > @_maxEntries
        @_split insertPath, level
        level--
      else
        break
    
    # adjust bboxes along the insertion path
    @_adjustParentBBoxes bbox, insertPath, level
    return

  
  # split overflowed node into two
  _split: (insertPath, level) ->
    node = insertPath[level]
    M = node.children.length
    m = @_minEntries
    @_chooseSplitAxis node, m, M
    newNode =
      children: node.children.splice(@_chooseSplitIndex(node, m, M))
      height: node.height

    newNode.leaf = true  if node.leaf
    @_calcBBox node
    @_calcBBox newNode
    if level
      insertPath[level - 1].children.push newNode
    else
      @_splitRoot node, newNode
    return

  _splitRoot: (node, newNode) ->
    
    # split root node
    @data = {}
    @data.children = [
      node
      newNode
    ]
    @data.height = node.height + 1
    @_calcBBox @data
    return

  _chooseSplitIndex: (node, m, M) ->
    i = undefined
    bbox1 = undefined
    bbox2 = undefined
    overlap = undefined
    area = undefined
    minOverlap = undefined
    minArea = undefined
    index = undefined
    minOverlap = minArea = Infinity
    i = m
    while i <= M - m
      bbox1 = @_distBBox(node, 0, i)
      bbox2 = @_distBBox(node, i, M)
      overlap = @_intersectionArea(bbox1, bbox2)
      area = @_area(bbox1) + @_area(bbox2)
      
      # choose distribution with minimum overlap
      if overlap < minOverlap
        minOverlap = overlap
        index = i
        minArea = (if area < minArea then area else minArea)
      else if overlap is minOverlap
        
        # otherwise choose distribution with minimum area
        if area < minArea
          minArea = area
          index = i
      i++
    index

  
  # sorts node children by the best axis for split
  _chooseSplitAxis: (node, m, M) ->
    compareMinX = (if node.leaf then @compareMinX else @_compareNodeMinX)
    compareMinY = (if node.leaf then @compareMinY else @_compareNodeMinY)
    xMargin = @_allDistMargin(node, m, M, compareMinX)
    yMargin = @_allDistMargin(node, m, M, compareMinY)
    
    # if total distributions margin value is minimal for x, sort by minX,
    # otherwise it's already sorted by minY
    node.children.sort compareMinX  if xMargin < yMargin
    return

  
  # total margin of all possible split distributions
  # where each node is at least m full
  _allDistMargin: (node, m, M, compare) ->
    node.children.sort compare
    leftBBox = @_distBBox(node, 0, m)
    rightBBox = @_distBBox(node, M - m, M)
    margin = @_margin(leftBBox) + @_margin(rightBBox)
    i = undefined
    child = undefined
    i = m
    while i < M - m
      child = node.children[i]
      @_extend leftBBox, (if node.leaf then @toBBox(child) else child.bbox)
      margin += @_margin(leftBBox)
      i++
    i = M - m - 1
    while i >= m
      child = node.children[i]
      @_extend rightBBox, (if node.leaf then @toBBox(child) else child.bbox)
      margin += @_margin(rightBBox)
      i--
    margin

  
  # min bounding rectangle of node children from k to p-1
  _distBBox: (node, k, p) ->
    bbox = @_empty()
    i = k
    child = undefined

    while i < p
      child = node.children[i]
      @_extend bbox, (if node.leaf then @toBBox(child) else child.bbox)
      i++
    bbox

  
  # calculate node's bbox from bboxes of its children
  _calcBBox: (node) ->
    node.bbox = @_distBBox(node, 0, node.children.length)
    return

  _adjustParentBBoxes: (bbox, path, level) ->
    
    # adjust bboxes along the given tree path
    i = level

    while i >= 0
      @_extend path[i].bbox, bbox
      i--
    return

  _condense: (path) ->
    
    # go through the path, removing empty nodes and updating bboxes
    i = path.length - 1
    siblings = undefined

    while i >= 0
      if path[i].children.length is 0
        if i > 0
          siblings = path[i - 1].children
          siblings.splice siblings.indexOf(path[i]), 1
        else
          @clear()
      else
        @_calcBBox path[i]
      i--
    return

  _contains: (a, b) ->
    a[0] <= b[0] and a[1] <= b[1] and b[2] <= a[2] and b[3] <= a[3]

  _intersects: (a, b) ->
    b[0] <= a[2] and b[1] <= a[3] and b[2] >= a[0] and b[3] >= a[1]

  _extend: (a, b) ->
    a[0] = Math.min(a[0], b[0])
    a[1] = Math.min(a[1], b[1])
    a[2] = Math.max(a[2], b[2])
    a[3] = Math.max(a[3], b[3])
    a

  _area: (a) ->
    (a[2] - a[0]) * (a[3] - a[1])

  _margin: (a) ->
    (a[2] - a[0]) + (a[3] - a[1])

  _enlargedArea: (a, b) ->
    (Math.max(b[2], a[2]) - Math.min(b[0], a[0])) *
    (Math.max(b[3], a[3]) - Math.min(b[1], a[1]))

  _intersectionArea: (a, b) ->
    minX = Math.max(a[0], b[0])
    minY = Math.max(a[1], b[1])
    maxX = Math.min(a[2], b[2])
    maxY = Math.min(a[3], b[3])
    Math.max(0, maxX - minX) * Math.max(0, maxY - minY)

  _empty: ->
    [
      Infinity
      Infinity
      -Infinity
      -Infinity
    ]

  _compareNodeMinX: (a, b) ->
    a.bbox[0] - b.bbox[0]

  _compareNodeMinY: (a, b) ->
    a.bbox[1] - b.bbox[1]

  _initFormat: (format) ->
    
    # data format (minX, minY, maxX, maxY accessors)
    
    # uses eval-type function compilation instead of just
    # accepting a toBBox function
    # because the algorithms are very sensitive to sorting
    # functions performance,
    # so they should be dead simple and without inner calls
    
    # jshint evil: true
    compareArr = [
      "return a"
      " - b"
      ";"
    ]
    @compareMinX = new Function("a", "b", compareArr.join(format[0]))
    @compareMinY = new Function("a", "b", compareArr.join(format[1]))
    @toBBox = new Function("a", "return [a" + format.join(", a") + "];")
    return
    
exports.rbush = rbush
