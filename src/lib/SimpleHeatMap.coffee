#https://github.com/mourner/simpleheat
simpleheat = (canvas) ->
  # jshint newcap: false, validthis: true
  return new simpleheat(canvas)  unless this instanceof simpleheat
  @_canvas = canvas =
    if typeof canvas is "string"
      document.getElementById(canvas)
    else
      canvas
  @_ctx = canvas.getContext("2d")
  @_width = canvas.width
  @_height = canvas.height
  @_max = 1
  @_data = []
  return
simpleheat:: =
  defaultRadius: 25
  defaultGradient:
    483: "blue"
    504: "cyan"
    525: "lime"
    546: "yellow"
    1: "red"

  data: (data) ->
    @_data = data
    this

  max: (max) ->
    @_max = max
    this

  add: (point) ->
    @_data.push point
    this

  clear: ->
    @_data = []
    this

  radius: (r, blur) ->
    blur = blur or 15
    
    # create a grayscale blurred circle image that we'll use for drawing points
    circle = @_circle = document.createElement("canvas")
    ctx = circle.getContext("2d")
    r2 = @_r = r + blur
    circle.width = circle.height = r2 * 2
    ctx.shadowOffsetX = ctx.shadowOffsetY = 200
    ctx.shadowBlur = blur
    ctx.shadowColor = "black"
    ctx.beginPath()
    ctx.arc r2 - 200, r2 - 200, r, 0, Math.PI * 2, true
    ctx.closePath()
    ctx.fill()
    this

  gradient: (grad) ->
    
    # create a 256x1 gradient that we'll use to turn
    # a grayscale heatmap into a colored one
    canvas = document.createElement("canvas")
    ctx = canvas.getContext("2d")
    gradient = ctx.createLinearGradient(0, 0, 0, 256)
    canvas.width = 1
    canvas.height = 256
    for i of grad
      gradient.addColorStop i, grad[i]
    ctx.fillStyle = gradient
    ctx.fillRect 0, 0, 1, 256
    @_grad = ctx.getImageData(0, 0, 1, 256).data
    this

  draw: (minOpacity) ->
    @radius @defaultRadius  unless @_circle
    @gradient @defaultGradient  unless @_grad
    ctx = @_ctx
    ctx.clearRect 0, 0, @_width, @_height
    
    # draw a grayscale heatmap by putting a blurred circle at each data point
    i = 0
    len = @_data.length
    p = undefined

    while i < len
      p = @_data[i]
      ctx.globalAlpha = Math.max(p[2] / @_max, minOpacity or 0.05)
      ctx.drawImage @_circle, p[0] - @_r, p[1] - @_r
      i++
    
    # colorize the heatmap, using opacity value of
    # each pixel to get the right color from our gradient
    colored = ctx.getImageData(0, 0, @_width, @_height)
    @_colorize colored.data, @_grad
    ctx.putImageData colored, 0, 0
    this

  _colorize: (pixels, gradient) ->
    i = 3
    len = pixels.length
    j = undefined

    while i < len
      j = pixels[i] * 4 # get gradient color from opacity value
      if j
        pixels[i - 3] = gradient[j]
        pixels[i - 2] = gradient[j + 1]
        pixels[i - 1] = gradient[j + 2]
      i += 4
    return

window.simpleheat = simpleheat