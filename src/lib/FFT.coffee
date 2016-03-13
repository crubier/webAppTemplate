# Computes the discrete Fourier transform (DFT) of the given
# complex vector, storing the result back into the vector.
# The vector can have any length. This is a wrapper function.
transform = (real, imag) ->
  throw (Error "Mismatched lengths") unless real.length is imag.length
  n = real.length
  if n is 0
    return
  else if (n & (n - 1)) is 0 # Is power of 2
    transformRadix2 real, imag
  # More complicated algorithm for arbitrary sizes
  else
    transformBluestein real, imag
  return

# Computes the inverse discrete Fourier transform (IDFT) of
# the given complex vector, storing the result back into the vector.
# The vector can have any length. This is a wrapper function.
# This transform does not perform scaling, so the inverse is not a true inverse.
inverseTransform = (real, imag) ->
  transform imag, real
  return

# Computes the discrete Fourier transform (DFT) of
# the given complex vector, storing the result back into the vector.
# The vectors length must be a power of 2. Uses the Cooley-Tukey
# decimation-in-time radix-2 algorithm.
transformRadix2 = (real, imag) ->
  
  # Initialization
  # Trivial transform
  # Equal to log2(n)
  
  # Bit-reversed addressing permutation
  
  # Cooley-Tukey decimation-in-time radix-2 FFT
  
  # Returns the integer whose value is the reverse of
  # the lowest 'bits' bits of the integer 'x'.
  reverseBits = (x, bits) ->
    y = 0
    i = 0

    while i < bits
      y = (y << 1) | (x & 1)
      x >>>= 1
      i++
    y
  throw (Error "Mismatched lengths") unless real.length is imag.length
  n = real.length
  return  if n is 1
  levels = -1
  i = 0

  while i < 32
    levels = i  if 1 << i is n
    i++
  throw (Error "Length is not a power of two") if levels is -1
  cosTable = new Array(n / 2)
  sinTable = new Array(n / 2)
  i = 0

  while i < n / 2
    cosTable[i] = Math.cos(2 * Math.PI * i / n)
    sinTable[i] = Math.sin(2 * Math.PI * i / n)
    i++
  i = 0

  while i < n
    j = reverseBits(i, levels)
    if j > i
      temp = real[i]
      real[i] = real[j]
      real[j] = temp
      temp = imag[i]
      imag[i] = imag[j]
      imag[j] = temp
    i++
  size = 2

  while size <= n
    halfsize = size / 2
    tablestep = n / size
    i = 0

    while i < n
      j = i
      k = 0

      while j < i + halfsize
        tpre =
          real[j + halfsize] * cosTable[k] + imag[j + halfsize] * sinTable[k]
        tpim =
          -real[j + halfsize] * sinTable[k] + imag[j + halfsize] * cosTable[k]
        real[j + halfsize] = real[j] - tpre
        imag[j + halfsize] = imag[j] - tpim
        real[j] += tpre
        imag[j] += tpim
        j++
        k += tablestep
      i += size
    size *= 2
  return

# Computes the discrete Fourier transform (DFT) of the
# given complex vector, storing the result back into the vector.
# The vector can have any length. This requires the convolution function,
# which in turn requires the radix-2 FFT function.
# Uses Bluesteins chirp z-transform algorithm.
transformBluestein = (real, imag) ->
  
  # Find a power-of-2 convolution length m such that m >= n * 2 + 1
  throw (Error "Mismatched lengths") unless real.length is imag.length
  n = real.length
  m = 1
  m *= 2  while m < n * 2 + 1
  
  # Trignometric tables
  cosTable = new Array(n)
  sinTable = new Array(n)
  i = 0

  while i < n
    j = i * i % (n * 2) # This is more accurate than j = i * i
    cosTable[i] = Math.cos(Math.PI * j / n)
    sinTable[i] = Math.sin(Math.PI * j / n)
    i++
  
  # Temporary vectors and preprocessing
  areal = new Array(m)
  aimag = new Array(m)
  i = 0

  while i < n
    areal[i] = real[i] * cosTable[i] + imag[i] * sinTable[i]
    aimag[i] = -real[i] * sinTable[i] + imag[i] * cosTable[i]
    i++
  i = n

  while i < m
    areal[i] = aimag[i] = 0
    i++
  breal = new Array(m)
  bimag = new Array(m)
  breal[0] = cosTable[0]
  bimag[0] = sinTable[0]
  i = 1

  while i < n
    breal[i] = breal[m - i] = cosTable[i]
    bimag[i] = bimag[m - i] = sinTable[i]
    i++
  i = n

  while i <= m - n
    breal[i] = bimag[i] = 0
    i++
  
  # Convolution
  creal = new Array(m)
  cimag = new Array(m)
  convolveComplex areal, aimag, breal, bimag, creal, cimag
  
  # Postprocessing
  i = 0

  while i < n
    real[i] = creal[i] * cosTable[i] + cimag[i] * sinTable[i]
    imag[i] = -creal[i] * sinTable[i] + cimag[i] * cosTable[i]
    i++
  return

# Computes the circular convolution of the given real vectors.
# Each vectors length must be the same.
convolveReal = (x, y, out) ->
  if x.length isnt y.length or x.length isnt out.length
    throw (Error "Mismatched lengths")
  zeros = new Array(x.length)
  i = 0
  while i < zeros.length
    zeros[i] = 0
    i++
  convolveComplex x, zeros, y, zeros.slice(0), out, zeros.slice(0)
  return
exports.convolveReal = convolveReal

# Computes the circular convolution of the given complex vectors.
# Each vectors length must be the same.
convolveComplex = (xreal, ximag, yreal, yimag, outreal, outimag) ->
  if (
    xreal.length isnt ximag.length or xreal.length isnt yreal.length or
    yreal.length isnt yimag.length or xreal.length isnt outreal.length or
    outreal.length isnt outimag.length
    )
    throw (Error "Mismatched lengths")
  n = xreal.length
  xreal = xreal.slice(0)
  ximag = ximag.slice(0)
  yreal = yreal.slice(0)
  yimag = yimag.slice(0)
  transform xreal, ximag
  transform yreal, yimag
  i = 0

  while i < n
    temp = xreal[i] * yreal[i] - ximag[i] * yimag[i]
    ximag[i] = ximag[i] * yreal[i] + xreal[i] * yimag[i]
    xreal[i] = temp
    i++
  inverseTransform xreal, ximag
  i = 0 # Scaling (because this FFT implementation omits it)

  while i < n
    outreal[i] = xreal[i] / n
    outimag[i] = ximag[i] / n
    i++
  return

# finds next power of two of the number n
nextPow2 = (n) ->
  m = n
  i = 0
  while m >= 1
    m = m >>> 1
    i++
  1 << i

# Generate the spectrum array for a given filter spectrum function
generateSpectrum= (length,dt,spectrumfunction) ->
  correct=(i)->(i*2)/(length*dt)
  if length%%2==1
    templen = (length - 1)/2
    temp = (spectrumfunction(correct(i)) for i in [1..templen])
    res = [spectrumfunction(correct(0))].concat(temp).concat(temp.reverse())
  else
    templen = (length - 2)/2
    temp = (spectrumfunction(correct(i)) for i in [1..templen])
    res = [spectrumfunction(correct(0))]
      .concat(temp)
      .concat([spectrumfunction(correct(templen))])
      .concat(temp.reverse())
  res

#Spectrum functions, with f in hertz
#First order low pass
lowPass = (f0) -> (f) -> Math.exp(-1*(f/f0)**2)
exports.lowPass= lowPass
#First order high pass
highPass = (f0) -> (f) -> 1-Math.exp(-1*(f/f0)**2)
exports.highPass= highPass
#First order band pass
bandPass = (flow,fhigh) ->
  (f)->(1-Math.exp(-1*(f/fhigh)**2))*Math.exp(-1*(f/flow)**2)
exports.bandPass= bandPass

# Filter a vector using an optimal radix-2 FFT and
# padding accordingly with a given minimum margin
filter = (vector,dt,margin,spectrumfunction) ->
  #Size for the fft
  size = nextPow2(vector.length + 2 * margin)
  #Left padding sizet
  sizeStart =
    if (size - vector.length) %% 2 == 0
      (size - vector.length)/2
    else
      (size - vector.length + 1)/2
  #Right padding size
  sizeEnd =
    if (size - vector.length) %% 2 == 0
      (size - vector.length)/2
    else
      (size - vector.length - 1)/2
  #Left padding content
  start = vector[0]
  #Right padding content
  end = vector[vector.length-1]
  #Padded signal
  realsig = (start for i in [1..sizeStart])
    .concat(vector)
    .concat(end for i in [1..sizeEnd])
  imagsig = (0 for i in [1..size])
  #Direct transform
  transformRadix2(realsig, imagsig)
  #Compute spectrum transform
  processSpectrum = generateSpectrum(size,dt,spectrumfunction)
  #Apply spectrum transform
  realsig = ((processSpectrum[i] * realsig[i]) for i in [0...size] )
  imagsig = ((processSpectrum[i] * imagsig[i]) for i in [0...size] )
  #Inverse transform
  transformRadix2(imagsig,realsig)
  #Scaling
  realsig = ((realsig[i] / size) for i in [0...size] )
  #De-Padding
  realsig=realsig.slice(sizeStart,size-sizeEnd)
  return realsig
exports.filter = filter

#Attempt at resizing function, but interpolation is much better
# resize =(vector,size)->
#   if(vector.length==size)
#     return vector.slice(0)
#   if(vector.length<size)
#     realsig = vector.slice(0)
#     imagsig = (0 for i in [1..vector.length])
#     transform(realsig,imagsig)
#     realsig = realsig[0..Math.ceil(vector.length/2)]
#       .concat(0 for i in [1..size-vector.length])
#       .concat(realsig[Math.ceil(vector.length/2)..-1])
#     imagsig = imagsig[0..Math.ceil(vector.length/2)]
#       .concat(0 for i in [1..size-vector.length])
#       .concat(imagsig[Math.ceil(vector.length/2)..-1])
#     transform(imagsig,realsig)
#     realsig = ((realsig[i] / vector.length) for i in [0...size] )
#     return realsig
#   if(vector.length>size)
#     realsig = vector.slice(0)
#     imagsig = (0 for i in [1..vector.length])
#     transform(realsig,imagsig)
#     realsig = realsig.splice(
#       Math.ceil(vector.length/2)-Math.floor((vector.length-size)/2),
#       vector.length-size
#     )
#     imagsig = imagsig.splice(
#       Math.ceil(vector.length/2)-Math.floor((vector.length-size)/2),
#       vector.length-size
#     )
#     transform(imagsig,realsig)
#     realsig = ((realsig[i] / vector.length) for i in [0...size] )
#     return realsig
