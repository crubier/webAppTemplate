d3 =          require 'd3'
React =       require 'react'
ReactART =    require 'react-art'
DSP =         require '../lib/dsp.coffee'
ArrayUtil =   require '../lib/array.coffee'
Simplify =    require '../lib/simplify.coffee'
ReactAsync =  require 'react-async'

Group = ReactART.Group
Shape = ReactART.Shape
Surface = ReactART.Surface
Transform = ReactART.Transform
Chart = React.createClass
  render: ->
    Surface {width:@props.width, height:@props.height},
      @props.children

Line = React.createClass
  getDefaultProps: ->
    {
      path: '',
      color: 'red',
      width: 1
    }

  render: ->
    Shape {d:@props.path, stroke:@props.color, strokeWidth:@props.width}


DataSeries = React.createClass
  getDefaultProps: ->
    {
      title: '',
      data: [],
      interpolate: 'linear',
    }
  render: ->
    createPath =
      d3.svg.line()
        .x((d)=> @props.xScale(d[0]))
        .y((d)=> @props.yScale(d[1]))
        .interpolate(@props.interpolate)

    Line {path:createPath(@props.data), color:@props.color}

LineChart = React.createClass

  getDefaultProps: ->
    {
      width: 600,
      height: 300,
      data:[[[]]]
    }

  render: ->
    maxlength = 2000
    data = for d in @props.data
      if d.length> maxlength
        console.log "resizing #{d.length}"
        temp= ArrayUtil.transpose(d)
        temp[0] = DSP.resize(temp[0],maxlength)
        temp[1] = DSP.resize(temp[1],maxlength)
        ArrayUtil.transpose(temp)
        # Simplify.simplify2D(d,10,false)
      else
        d


    size = { width: @props.width, height: @props.height }

    ymax = 0
    (((ymax = Math.max(ymax,val[1])) for val in serie) for serie in data)
    xmax = 0
    (((xmax = Math.max(xmax,val[0])) for val in serie) for serie in data)


    xScale = d3.scale.linear().domain([0, xmax])
      .range([0, @props.width])

    yScale = d3.scale.linear().domain([0, ymax])
      .range([@props.height, 0])

    dataseries =
      for i in [0...data.length]
        DataSeries({
          data:data[i],
          size:size,
          xScale:xScale,
          yScale:yScale,
          key:"#{i}",
          ref:"series#{i}",
          color:"hsl(#{360*i/data.length},100,50)"
        })

    # console.log "LineChartRender"

    Chart {width:@props.width, height:@props.height},
      dataseries


module.exports = LineChart
