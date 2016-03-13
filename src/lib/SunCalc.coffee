
# sun calculations are based on
# http://aa.quae.nl/en/reken/zonpositie.html formulas

# date/time constants and conversions
toJulian = (date) ->
  date.valueOf() / dayMs - 0.5 + J1970
fromJulian = (j) ->

  new Date((j + 0.5 - J1970) * dayMs)
toDays = (date) ->
  toJulian(date) - J2000

# general calculations for position
# obliquity of the Earth
rightAscension = (l, b) ->
  atan sin(l) * cos(e) - tan(b) * sin(e), cos(l)
declination = (l, b) ->
  asin sin(b) * cos(e) + cos(b) * sin(e) * sin(l)
azimuth = (H, phi, dec) ->
  atan sin(H), cos(H) * sin(phi) - tan(dec) * cos(phi)
altitude = (H, phi, dec) ->
  asin sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H)
siderealTime = (d, lw) ->
  rad * (280.16 + 360.9856235 * d) - lw

# general sun calculations
solarMeanAnomaly = (d) ->
  rad * (357.5291 + 0.98560028 * d)
eclipticLongitude = (M) ->
  C = rad * (1.9148 * sin(M) + 0.02 * sin(2 * M) + 0.0003 * sin(3 * M))
  # equation of center
  P = rad * 102.9372 # perihelion of the Earth
  M + C + P + PI
sunCoords = (d) ->
  M = solarMeanAnomaly(d)
  L = eclipticLongitude(M)
  dec: declination(L, 0)
  ra: rightAscension(L, 0)

# calculates sun position for a given date and latitude/longitude

# sun times configuration (angle, morning name, evening name)

# adds a custom time to the times config

# calculations for sun times
julianCycle = (d, lw) ->
  Math.round d - J0 - lw / (2 * PI)
approxTransit = (Ht, lw, n) ->
  J0 + (Ht + lw) / (2 * PI) + n
solarTransitJ = (ds, M, L) ->
  J2000 + ds + 0.0053 * sin(M) - 0.0069 * sin(2 * L)
hourAngle = (h, phi, d) ->
  acos (sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d))

# returns set time for the given sun altitude
getSetJ = (h, lw, phi, dec, n, M, L) ->
  w = hourAngle(h, phi, dec)
  a = approxTransit(w, lw, n)
  solarTransitJ a, M, L

# calculates sun times for a given date and latitude/longitude

# moon calculations, based on
# http://aa.quae.nl/en/reken/hemelpositie.html formulas
moonCoords = (d) -> # geocentric ecliptic coordinates of the moon
  L = rad * (218.316 + 13.176396 * d) # ecliptic longitude
  M = rad * (134.963 + 13.064993 * d) # mean anomaly
  F = rad * (93.272 + 13.229350 * d) # mean distance
  l = L + rad * 6.289 * sin(M) # longitude
  b = rad * 5.128 * sin(F) # latitude
  dt = 385001 - 20905 * cos(M) # distance to the moon in km
  ra: rightAscension(l, b)
  dec: declination(l, b)
  dist: dt
PI = Math.PI
sin = Math.sin
cos = Math.cos
tan = Math.tan
asin = Math.asin
atan = Math.atan2
acos = Math.acos
rad = PI / 180
dayMs = 1000 * 60 * 60 * 24
J1970 = 2440588
J2000 = 2451545
e = rad * 23.4397
SunCalc = {}
SunCalc.getPosition = (date, lat, lng) ->
  lw = rad * -lng
  phi = rad * lat
  d = toDays(date)
  c = sunCoords(d)
  H = siderealTime(d, lw) - c.ra
  azimuth: azimuth(H, phi, c.dec)
  altitude: altitude(H, phi, c.dec)

times = SunCalc.times = [
  [
    -0.833
    "sunrise"
    "sunset"
  ]
  [
    -0.3
    "sunriseEnd"
    "sunsetStart"
  ]
  [
    -6
    "dawn"
    "dusk"
  ]
  [
    -12
    "nauticalDawn"
    "nauticalDusk"
  ]
  [
    -18
    "nightEnd"
    "night"
  ]
  [
    6
    "goldenHourEnd"
    "goldenHour"
  ]
]
SunCalc.addTime = (angle, riseName, setName) ->
  times.push [
    angle
    riseName
    setName
  ]
  return

J0 = 0.0009
SunCalc.getTimes = (date, lat, lng) ->
  lw = rad * -lng
  phi = rad * lat
  d = toDays(date)
  n = julianCycle(d, lw)
  ds = approxTransit(0, lw, n)
  M = solarMeanAnomaly(ds)
  L = eclipticLongitude(M)
  dec = declination(L, 0)
  Jnoon = solarTransitJ(ds, M, L)
  i = undefined
  len = undefined
  time = undefined
  Jset = undefined
  Jrise = undefined
  result =
    solarNoon: fromJulian(Jnoon)
    nadir: fromJulian(Jnoon - 0.5)

  i = 0
  len = times.length

  while i < len
    time = times[i]
    Jset = getSetJ(time[0] * rad, lw, phi, dec, n, M, L)
    Jrise = Jnoon - (Jset - Jnoon)
    result[time[1]] = fromJulian(Jrise)
    result[time[2]] = fromJulian(Jset)
    i += 1
  result

SunCalc.getMoonPosition = (date, lat, lng) ->
  lw = rad * -lng
  phi = rad * lat
  d = toDays(date)
  c = moonCoords(d)
  H = siderealTime(d, lw) - c.ra
  h = altitude(H, phi, c.dec)
  
  # altitude correction for refraction
  h = h + rad * 0.017 / tan(h + rad * 10.26 / (h + rad * 5.10))
  azimuth: azimuth(H, phi, c.dec)
  altitude: h
  distance: c.dist


# calculations for illumination parameters of the moon,
# based on http://idlastro.gsfc.nasa.gov/ftp/pro/astro/mphase.pro formulas and
# Chapter 48 of "Astronomical Algorithms"
# 2nd edition by Jean Meeus (Willmann-Bell, Richmond) 1998.
SunCalc.getMoonIllumination = (date) ->
  d = toDays(date)
  s = sunCoords(d)
  m = moonCoords(d)
  sdist = 149598000 # distance from Earth to Sun in km
  phi = acos(sin(s.dec) * sin(m.dec) +
    cos(s.dec) * cos(m.dec) * cos(s.ra - m.ra))
  inc = atan(sdist * sin(phi), m.dist - sdist * cos(phi))
  angle = atan(cos(s.dec) * sin(s.ra - m.ra), sin(s.dec) *
    cos(m.dec) - cos(s.dec) * sin(m.dec) * cos(s.ra - m.ra))
  fraction: (1 + cos(inc)) / 2
  phase: 0.5 + 0.5 * inc * ((if angle < 0 then -1 else 1)) / Math.PI
  angle: angle

module.exports = SunCalc