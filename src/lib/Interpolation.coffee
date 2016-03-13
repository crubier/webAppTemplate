
#Gives ceil of the index if element not found
binaryIndexOf = (array,searchElement) ->
  minIndex = 0
  maxIndex = array.length - 1
  currentIndex = undefined
  currentElement = undefined
  while minIndex < maxIndex - 1
    currentIndex = Math.floor((minIndex + maxIndex) / 2)
    currentElement = array[currentIndex]
    if currentElement < searchElement
      minIndex = currentIndex
    else if currentElement > searchElement
      maxIndex = currentIndex
    else
      return currentIndex
  return if currentElement<searchElement then currentIndex+1 else currentIndex



# test = (xs,x)->
#   i = 1
#   i++  while xs[i] < x
#   i

# xs = [0,1,2,3,4,5,6,7,8.654321,9,10]
# x= 8.65432a
# # console.log test  xs,x
# console.log binaryIndexOf  xs,x

# from http://blog.ivank.net/interpolation-with-cubic-splines.html
splineInterpolator = (xs, ys) ->
  ks = []
  ks[0] = (ys[1]-ys[0]) / (xs[1]-xs[0])
  for i in [1..xs.length-2]
    ks[i]=((ys[i+1]-ys[i])/ (2*(xs[i+1]-xs[i])) +
        (ys[i]-ys[i-1])/ (2*(xs[i]-xs[i-1])))
  ks[xs.length-1]=
    (ys[xs.length-1]-ys[xs.length-2]) / (xs[xs.length-1]-xs[xs.length-2])
  (x) ->
    i = binaryIndexOf xs, x
    t = (x - xs[i - 1]) / (xs[i] - xs[i - 1])
    a = ks[i - 1] * (xs[i] - xs[i - 1]) - (ys[i] - ys[i - 1])
    b = -ks[i] * (xs[i] - xs[i - 1]) + (ys[i] - ys[i - 1])
    q = (1 - t) * ys[i - 1] + t * ys[i] + t * (1 - t) * (a * (1 - t) + b * t)
    q
exports.splineInterpolator = splineInterpolator

#http://en.wikipedia.org/wiki/Monotone_cubic_interpolation
#http://math.stackexchange.com/questions/45218/implementation-of-monotone-cubic-interpolation
monotonicSplineInterpolator = (xs, ys) ->
  ks=[]
  ks[0] = 0
  for i in [1..xs.length-2]
    hi=xs[i+1]-xs[i]
    him=xs[i]-xs[i-1]
    di=(ys[i+1]-ys[i])/hi
    dim=(ys[i]-ys[i-1])/him
    ks[i] =
      if((di>=0 and dim >=0) or (di<0 and dim <0))
        (3*(him+hi)/((2*hi+him)/dim + (hi+2*him)/di))
      else
        0
  ks[xs.length-1]=0
  (x) ->
    i = binaryIndexOf xs, x
    t = (x - xs[i - 1]) / (xs[i] - xs[i - 1])
    a = ks[i - 1] * (xs[i] - xs[i - 1]) - (ys[i] - ys[i - 1])
    b = -ks[i] * (xs[i] - xs[i - 1]) + (ys[i] - ys[i - 1])
    q = (1 - t) * ys[i - 1] + t * ys[i] + t * (1 - t) * (a * (1 - t) + b * t)
    q
exports.monotonicSplineInterpolator = monotonicSplineInterpolator
