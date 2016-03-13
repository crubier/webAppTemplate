#
# (c) 2013, Vladimir Agafonkin
# Simplify.js, a high-performance JS polyline simplification library
# mourner.github.io/simplify-js
#

# to suit your point format, run search/replace for '[0]' and '[1]';
# for 3D version, see 3d branch
# (configurability would draw significant performance overhead)

# square distance between 2 points
getSqDist = (p1, p2) ->
  dx = p1[0] - p2[0]
  dy = p1[1] - p2[1]
  dx * dx + dy * dy

# square distance from a point to a segment
getSqSegDist = (p, p1, p2) ->
  x = p1[0]
  y = p1[1]
  dx = p2[0] - x
  dy = p2[1] - y
  if dx isnt 0 or dy isnt 0
    t = ((p[0] - x) * dx + (p[1] - y) * dy) / (dx * dx + dy * dy)
    if t > 1
      x = p2[0]
      y = p2[1]
    else if t > 0
      x += dx * t
      y += dy * t
  dx = p[0] - x
  dy = p[1] - y
  dx * dx + dy * dy

# rest of the code doesn't care about point format

# basic distance-based simplification
simplifyRadialDist = (points, sqTolerance) ->
  prevPoint = points[0]
  newPoints = [prevPoint]
  point = undefined
  i = 1
  len = points.length

  while i < len
    point = points[i]
    if getSqDist(point, prevPoint) > sqTolerance
      newPoints.push point
      prevPoint = point
    i++
  newPoints.push point  if prevPoint isnt point
  newPoints

# simplification using optimized Douglas-Peucker
# algorithm with recursion elimination
simplifyDouglasPeucker = (points, sqTolerance) ->
  len = points.length
  MarkerArray =
    (if (typeof Uint8Array)? then Uint8Array else Array)
  markers = new MarkerArray(len)
  first = 0
  last = len - 1
  stack = []
  newPoints = []
  i = undefined
  maxSqDist = undefined
  sqDist = undefined
  index = undefined
  markers[first] = markers[last] = 1
  while last
    maxSqDist = 0
    i = first + 1
    while i < last
      sqDist = getSqSegDist(points[i], points[first], points[last])
      if sqDist > maxSqDist
        index = i
        maxSqDist = sqDist
      i++
    if maxSqDist > sqTolerance
      markers[index] = 1
      stack.push first, index, index, last
    last = stack.pop()
    first = stack.pop()
  i = 0
  while i < len
    newPoints.push points[i]  if markers[i]
    i++
  newPoints

# both algorithms combined for awesome performance
simplify = (points, tolerance, highestQuality) ->
  return points if points.length <= 1
  sqTolerance =
    (if tolerance? then tolerance * tolerance else 1)
  points =
    (if highestQuality then points else simplifyRadialDist(points, sqTolerance))
  points = simplifyDouglasPeucker(points, sqTolerance)
  points

exports.simplify2D = simplify








# to suit your point format, run search/replace for '[0]', '[1]' and '[2]';
# (configurability would draw significant performance overhead)

# square distance between 2 points
getSquareDistance3D = (p1, p2) ->
  dx = p1[0] - p2[0]
  dy = p1[1] - p2[1]
  dz = p1[2] - p2[2]
  dx * dx + dy * dy + dz * dz

# square distance from a point to a segment
getSquareSegmentDistance3D = (p, p1, p2) ->
  x = p1[0]
  y = p1[1]
  z = p1[2]
  dx = p2[0] - x
  dy = p2[1] - y
  dz = p2[2] - z
  if dx isnt 0 or dy isnt 0 or dz isnt 0
    t = (
      ((p[0] - x) * dx + (p[1] - y) * dy + (p[2] - z) * dz) /
      (dx * dx + dy * dy + dz * dz)
      )
    if t > 1
      x = p2[0]
      y = p2[1]
      z = p2[2]
    else if t > 0
      x += dx * t
      y += dy * t
      z += dz * t
  dx = p[0] - x
  dy = p[1] - y
  dz = p[2] - z
  dx * dx + dy * dy + dz * dz

# the rest of the code doesn't care for the point format

# basic distance-based simplification
simplifyRadialDistance3D = (points, sqTolerance) ->
  prevPoint = points[0]
  newPoints = [prevPoint]
  point = undefined
  i = 1
  len = points.length

  while i < len
    point = points[i]
    if getSquareDistance3D(point, prevPoint) > sqTolerance
      newPoints.push point
      prevPoint = point
    i++
  newPoints.push point  if prevPoint isnt point
  newPoints

# simplification using optimized Douglas-Peucker algorithm
# with recursion elimination
simplifyDouglasPeucker3D = (points, sqTolerance) ->
  len = points.length
  MarkerArray = (if (typeof Uint8Array)? then Uint8Array else Array)
  markers = new MarkerArray(len)
  first = 0
  last = len - 1
  stack = []
  newPoints = []
  i = undefined
  maxSqDist = undefined
  sqDist = undefined
  index = undefined
  markers[first] = markers[last] = 1
  while last
    maxSqDist = 0
    i = first + 1
    while i < last
      sqDist =
        getSquareSegmentDistance3D(points[i], points[first], points[last])
      if sqDist > maxSqDist
        index = i
        maxSqDist = sqDist
      i++
    if maxSqDist > sqTolerance
      markers[index] = 1
      stack.push first, index, index, last
    last = stack.pop()
    first = stack.pop()
  i = 0
  while i < len
    newPoints.push points[i]  if markers[i]
    i++
  newPoints

# both algorithms combined for awesome performance
simplify3D = (points, tolerance, highestQuality) ->
  sqTolerance = (if tolerance? then tolerance * tolerance else 1)
  points =
    if highestQuality
      points
    else
      simplifyRadialDistance3D(points, sqTolerance)
  points = simplifyDouglasPeucker3D(points, sqTolerance)
  points



exports.simplify3D = simplify3D