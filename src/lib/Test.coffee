Computation = require './computation.js'
ArrayUtil = require './array.js'
DSP = require './dsp.js'
FFT = require './fft.js'

computations =
  raw: (filename) -> csvparse(filename)
  time: (raw) -> raw.time
  forwardacceleration : (forwardvelocity)->derivate(forwardvelocity)
  upacceleration : (raw) -> applyhighpassfilter(scale(raw.up,9.81), 600)
  rightacceleration : (raw) ->
    applyhighpassfilter(scale(raw.sideways,9.81), 600)
  forwardvelocity : (raw) ->
    sum(
      applyhighpassfilter(integrate(applyhighpassfilter(
        scale(raw.forward,9.81), 60)), 60),
      applylowpassfilter(applylowpassfilter(raw.veldpr, 60), 60))
  upvelocity : (raw,upacceleration)->
    sum(applyhighpassfilter(integrate(upacceleration), 60),
      applylowpassfilter(derivate(raw.upm)), 60)
  rightvelocity : (rightacceleration) ->
    applyhighpassfilter(integrate(rightacceleration), 60)
  forwardposition :(forwardvelocity)-> integrate(forwardvelocity)

computationTest =
  bob: (laSource) -> laSource + 1,
  joe: (laSource) -> Math.sin(laSource),
  res: (bob,joe) -> bob + joe,
  aha: (res,joe) -> res**joe,
  leRes: (aha) -> aha*2

# console.time "bob"
# console.time "prep"
# len=10*60*100
# sig = DSP.random(len)
# sigreal = sig.slice(0)
# sigcomp = DSP.scale(sig,0).slice(0)
# console.timeEnd "prep"
# console.time "proc"
# fftsig = FFT.transform(sigreal,sigcomp)
# invfftsig = FFT.inverseTransform(sigreal,sigcomp)
# console.timeEnd "proc"
# console.time "post"
# sigreal = DSP.divide(sigreal,len)
# console.log DSP.total(DSP.abs(sigcomp))
# console.log DSP.total(DSP.abs(sig))
# console.log DSP.total(DSP.abs(sigreal))
# console.log (DSP.total(DSP.abs(sigreal)) / DSP.total(DSP.abs(sig)))
# console.log DSP.total(DSP.abs(DSP.difference(sigreal,sig)))
# console.timeEnd "post"
# console.timeEnd "bob"

#See test.nb for checks in mathematica : validated
# console.time "filter"
# sig = DSP.random(60*100)
# result = FFT.filter(sig,0.01,1000,FFT.lowPass(0.1))
# console.log "signal={#{sig}};"
# console.log "result={#{result}};"
# console.timeEnd "filter"

#

# n=3
# l=10000
# console.time "testresizeInterpolation"
# for i in [1..n]
#   v = DSP.random(Math.random()*l+2*l)
#   DSP.resize(v,2*l).length
# console.timeEnd "testresizeInterpolation"
# console.time "testresizeInterpolation2"
# for i in [1..n]
#   v = DSP.random(Math.random()*l+2*l)
#   DSP.resize2(v,2*l).length
# console.timeEnd "testresizeInterpolation2"


# console.time "testresizeInterpolation"
# for i in [1..1]
#   len= 11352
#   r=13427
#   v = DSP.random(len)
#   console.log "signal={#{v}};"
#   console.log "result={#{DSP.resize(DSP.resize(v,r),len)}};"
#   console.log "result2={#{
#       DSP.resizeMonotonic(DSP.resizeMonotonic(v,r),len)
#       }};"
# console.timeEnd "testresizeInterpolation"


# console.time "FFT"
# console.log DSP.resize([5,5],100)
# console.timeEnd "FFT"

# console.log "a={#{
#   DSP.strokeAggregationToTimeData([1,2,10,0],[30,60,90,120],151)
#   }}"


