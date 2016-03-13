FFT = require './FFT.coffee'
# {Smooth} = require './libinterpolationOld.js'
Interpolation = require './Interpolation.coffee'

resize = (vector,size)->
  sizebef=vector.length
  if(sizebef==size)
    return vector.slice(0)
  else
    interpolator =
      new Interpolation.splineInterpolator(
        (k/(sizebef-1) for k in [0..sizebef-1]),vector
      )
    return (interpolator(k/(size-1)) for k in [0..size-1])
exports.resize = resize

scaleInside = (table,range) ->
  [mini,maxi]=range
  tablemin=table.reduce (previous,current)->
    ( if previous < current then previous else current )
  tablemax=table.reduce (previous,current)->
    ( if previous > current then previous else current )
  tablespan=Math.max(tablemax-tablemin,0.000001)
  table.map (tablevalue)->(mini+(maxi-mini)*(tablevalue-tablemin)/(tablespan))
exports.scaleInside = scaleInside

# scale a table
scale = (table,rangeFrom,rangeTo) ->
  [tablemin,tablemax] = rangeFrom
  [mini,maxi] = rangeTo
  tablespan=Math.max(tablemax-tablemin,0.000001)
  table.map (tablevalue)->(mini+(maxi-mini)*(tablevalue-tablemin)/(tablespan))
exports.scale = scale


#resize, using monotonic interpolation
resizeMonotonic = (vector,size)->
  sizebef=vector.length
  if(sizebef==size)
    return vector.slice(0)
  else
    interpolator =
      new Interpolation.monotonicSplineInterpolator(
        (k/(sizebef-1) for k in [0..sizebef-1]),vector
      )
    return (interpolator(k/(size-1)) for k in [0..size-1])
exports.resizeMonotonic = resizeMonotonic

add = (vector,coefficient)->
  (vector.map (x)->(x+coefficient))
exports.add = add

multiply = (vector,coefficient)->
  (vector.map (x)->(x*coefficient))
exports.multiply = multiply

substract = (vector,coefficient)->
  (vector.map (x)->(x-coefficient))
exports.substract = substract

divide = (vector,coefficient)->
  (vector.map (x)->(x/coefficient))
exports.divide = divide

sum = (vectora,vectorb)->
  for i in [0..Math.min(vectora.length, vectorb.length)-1]
    (vectora[i]+vectorb[i])
exports.sum = sum

product = (vectora,vectorb)->
  for i in [0..Math.min(vectora.length, vectorb.length)-1]
    (vectora[i]*vectorb[i])
exports.product = product

difference = (vectora,vectorb)->
  for i in [0..Math.min(vectora.length, vectorb.length)-1]
    (vectora[i]-vectorb[i])
exports.difference = difference

division = (vectora,vectorb)->
  for i in [0..Math.min(vectora.length, vectorb.length)-1]
    (vectora[i]/vectorb[i])
exports.division=division

power = (vectora,vectorb)->
  for i in [0..Math.min(vectora.length, vectorb.length)-1]
    (vectora[i]**vectorb[i])
exports.power=power

abs = (vector)->
  (Math.abs v for v in vector)
exports.abs=abs

derivate= (vector,dt)->
  res=[0]
  for i in [1...vector.length]
    res.push (vector[i] - vector[i-1])/dt
  res
exports.derivate = derivate

integrate = (vector,dt)->
  res=[0]
  for i in [1...vector.length]
    res.push (res[-1]+ vector[i])*dt
  res
exports.integrate = integrate

total = (vector) ->
  vector.reduce ((tot,val)->(tot+val)),0
exports.total=total

sign = (vector)->
  vector.map (x)->
    if x? then (if x >0 then 1 else (if x<0 then -1 else 0)) else 0
exports.sign = sign

signRatio = (vector) ->
  (total sign vector)/vector.length
exports.signRatio = signRatio

positiveValues = (vector) ->
  vector.map (x)->if x? then (if x >0 then x else 0) else 0
exports.positiveValues = positiveValues

negativeValues = (vector) ->
  vector.map (x)->if x? then (if x <0 then x else 0) else 0
exports.negativeValues = negativeValues

reverse = (vector) ->
  vector.reverse()
exports.reverse = reverse

applypadding =(vector, size)->
  start = vector[0]
  end = vector[vector.length-1]
  (start for i in [1..size]).concat(vector).concat(end for i in [1..size])
exports.applypadding =  applypadding

unapplypadding=(vector, size)->
  vector.slice size, vector.length-size
exports.unapplypadding =  unapplypadding

random = (size)->
  (Math.random() for i in [1..size])
exports.random =  random

lowpassfilter = (vector,dt,freq) ->
  FFT.filter(vector,dt,10/(dt*freq),FFT.lowPass(freq))
exports.lowpassfilter = lowpassfilter

highpassfilter = (vector,dt,freq) ->
  FFT.filter(vector,dt,10/(dt*freq),FFT.highPass(freq))
exports.highpassfilter = highpassfilter

bandpassfilter = (vector,dt,flow,fhigh) ->
  FFT.filter(vector,dt,10/(dt*flow),FFT.bandPass(flow,fhigh))
exports.bandpassfilter = bandpassfilter

mean = (vector) ->
  total(vector)/vector.length
exports.mean=mean

norm1 = (vector) ->
  total(abs(vector))
exports.norm1 = norm1

norm2 = (vector) ->
  Math.sqrt(total(product(vector,vector)))
exports.norm2 = norm2

normInf = (vector) ->
  [min,max] = range vector
  max-min
exports.normInf = normInf

range = (vector) ->
  vector.reduce(
    ((minmax,val)->([Math.min(minmax[0],val),Math.max(minmax[1],val)])),
    [vector[0],vector[1]]
  )
exports.range = range

max = (vector) ->
  (range vector)[1]
exports.max = max

min = (vector) ->
  (range vector)[0]
exports.min = min

crop =(data,range) ->
  res=[]
  for sample in data
    res.push Math.max(Math.min(sample,range[1]),range[0])
  return res
exports.crop = crop

normalizeLength =(data,size) ->
  res=[]
  for vector in data
    res.push resize(vector,size)
  return res
exports.normalizeLength = normalizeLength

normalizeValues =(data) ->
  res=[]
  for vector in data
    [min,max] = range vector
    res.push divide(substract(vector,min),(max-min))
  return res
exports.normalizeValues = normalizeValues

normalizeAll = (data,size) ->
  normalizeValues normalizeLength(data,size)
exports.normalizeAll = normalizeAll

normalizeOffset = (vector) ->
  substract(vector,vector[0])
exports.normalizeOffset=normalizeOffset

normalizeMean = (vector) ->
  substract(vector,mean(vector))
exports.normalizeMean=normalizeMean

applyFunction = (vector,func)->
  vector.map(func)
exports.applyFunction=applyFunction

strokePositions = (stkMark)->
  stkMark.reduce(
    ((previousValue, currentValue, index, array)->
      if currentValue==1 then previousValue.concat([index]) else previousValue),
    []
  )
exports.strokePositions = strokePositions

strokePositionsOffset = (strokepositions,offset,samplenumber) ->
  stkpos=strokepositions.slice(0)
  if stkpos[0]!=0
    stkpos.unshift(0)
  if stkpos[stkpos.length-1]!=samplenumber
    stkpos.push(samplenumber)
  for i in [0...stkpos.length-1]
    (Math.round((1-offset)*stkpos[i]+offset*stkpos[i+1]))
exports.strokePositionsOffset = strokePositionsOffset

timeDataToStrokeData = (vector, strokepositions) ->
  res = []
  for i in [0...strokepositions.length-1]
    res.push vector[strokepositions[i]..strokepositions[i+1]]
   return res
exports.timeDataToStrokeData = timeDataToStrokeData

strokeAggregationToTimeData =(data, strokepositions,samplenumber)->
  xs=strokepositions.slice(0)
  ys=data.slice(0)

  if strokepositions[0]!=0
    xs.unshift 0
    ys.unshift ys[0]

  if  strokepositions[strokepositions.length-1]!=samplenumber-1
    xs.push samplenumber-1
    ys.push ys[ys.length-1]

  interpolator = new Interpolation.monotonicSplineInterpolator(xs,ys)
  return (interpolator(k) for k in [0..samplenumber-1])
exports.strokeAggregationToTimeData = strokeAggregationToTimeData

# strokeDataToTimeData = (data, strokepositions,samplenumber)->

# strokedatatotimedata[serie_List, strokepositions_List,
#    samplenumber_Integer] := Module[
#    {res, interp, prev, next},
   
#    If[Length[serie] != Length[strokepositions] ,
          
#     printError[
#      "Stroke based series length incorrect : " <>
#       ToString[Length[serie]] <> " \[NotEqual] " <>
#       ToString[Length[strokepositions]]];
#           Return[Table[-1, {i, 1, samplenumber}]],
    
#     res = {};
#     (*lets resize elements of serie in order to be able to flatten \
# serie later*)
#     next = 0;
#     Do[
#      prev = next;
#      next = strokepositions[[i]];
     
#      res = Append[res, resize[serie[[i]], next - prev]];
     
#      ,
#      {i, Length[serie]}
#      ];
    
#     prev = next;
#     next = samplenumber;
    
#     res = Append[res, resize[serie[[-1]], next - prev]];
    
#     Return[Flatten[res]];
    
#     ]
#    ];

# markevents[serie_List, samplenumber_Integer] := Module[
#   {res},
  
#   res = Table[0, {samplenumber}];
#   Do[res[[serie[[i]]]] = 1, {i, Length[serie]}];
#   Return[res];
#   ]
#   ###