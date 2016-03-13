React = require 'react'
ReactART = require 'react-art'
d3 = require 'd3'
RouletteModel = require 'lib/Roulette.coffee'
DSP = require 'lib/Dsp.coffee'
chroma = require 'chroma-js'

Group = ReactART.Group
Shape = ReactART.Shape
Surface = ReactART.Surface
Rectangle = ReactART.Rectangle
Transform = ReactART.Transform

{svg,g,img,span,circle,polygon,div,path,input,form,button}=React.DOM

Roulette = React.createClass
  getDefaultProps: ->
    {
      tokenOrigin:{x:555,y:71.4},
      tokenStep:{x:26.9,y:33.1},
      tokenRadius:13,
      image:"image/European roulette layout tokens.svg",
      imageFrame:"image/European roulette layout frame.svg",
      rouletteOrigin:{x:243.5,y:225},
      rouletteRadius:127,
      # statistics:(Math.floor(10 + 10*Math.random()) for i in [0 .. 36]),
      statistics:(0 for i in [0 .. 36]),
      # statistics:((if i in [0] then 10 else 1) for i in [0 .. 36])
    }

  render: ->
    
    rouletteOrderedStatistics = (@props.statistics[i] for i in RouletteModel.order)
    rouletteOrderedStatistics = DSP.divide rouletteOrderedStatistics, Math.max(1,(DSP.max rouletteOrderedStatistics))

    colorfunction = chroma.scale(['darkblue','darkblue','blue','blue','lightblue','white','white','orange', 'red']).mode('lab');
    # .domain(DSP.range(rouletteOrderedStatistics));

    statisticsChart = g {},
      for value,index in rouletteOrderedStatistics
        pt0 = {x:@props.rouletteOrigin.x,y:@props.rouletteOrigin.y}
        pt1 = {x:@props.rouletteOrigin.x + @props.rouletteRadius * value * Math.cos(Math.PI * (0.5+2 * (index-0.5)/37)),y:@props.rouletteOrigin.y - @props.rouletteRadius * value * Math.sin(Math.PI * (0.5+2 * (index-0.5)/37))}
        pt2 = {x:@props.rouletteOrigin.x + @props.rouletteRadius * value * Math.cos(Math.PI * (0.5+2 * (index+0.5)/37)),y:@props.rouletteOrigin.y - @props.rouletteRadius * value * Math.sin(Math.PI * (0.5+2 * (index+0.5)/37))}
        points = "#{pt0.x},#{pt0.y} #{pt1.x},#{pt1.y} #{pt2.x},#{pt2.y}"
        polygon {key:index,points:points,style:{fill:colorfunction(value).hex(),stroke:'none','stroke-width':1}}
    
    statisticsChartAverage = circle {fill:"none", stroke:"#FFFFFF", cx:@props.rouletteOrigin.x,cy:@props.rouletteOrigin.y,r:@props.rouletteRadius * DSP.mean(rouletteOrderedStatistics)}
    betresults = RouletteModel.betExpectation @props.statistics

    possibleBets = RouletteModel.possibleBets()

    heuristic = (bet)->((coefficient=1)->Math.max(0,bet.result/(bet.risk ** coefficient)))

    max0= DSP.max(Math.max(heuristic(result)(0),0) for result in betresults)
    max1= DSP.max(Math.max(heuristic(result)(1),0) for result in betresults)
    max2= DSP.max(Math.max(heuristic(result)(2),0) for result in betresults)

    if max0==0 or max1==0 or max2==0 or isNaN(max0) or isNaN(max1) or isNaN(max2)
      return (
        div {className:"relative"},
          div {className:"absolute"},
            img {src:@props.image}
          div {className:"absolute"},
            svg {width:1382,height:472},
              g {},
                statisticsChart
                statisticsChartAverage
          # div {className:"absolute", width:300},
          #   img {src:@props.imageFrame}
        )


    colorfunction = (result)=>
      rgb=d3.rgb(255*heuristic(result)(0)/max0,255*heuristic(result)(1)/max1,255*heuristic(result)(2)/max2)
      hsl=rgb.hsl()
      d3.hsl(
        hsl.h,
        Math.pow(hsl.s,0.01),
        Math.pow(hsl.l,0.01)-Math.pow(1-hsl.l,0.01)+0.5
      ).toString()
      # rgb.toString()

    radiusfunction = (result)=>
      Math.max(
        @props.tokenRadius*heuristic(result)(0)/max0,
        @props.tokenRadius*heuristic(result)(1)/max1,
        @props.tokenRadius*heuristic(result)(2)/max2
        )

    tokens = []
    for result,index in betresults
      tokens.push circle({key:result.name ,fill:colorfunction(result), stroke:"none",  cx:@props.tokenOrigin.x + @props.tokenStep.x * possibleBets[result.name].position.x, cy:@props.tokenOrigin.y + @props.tokenStep.y * possibleBets[result.name].position.y, r:radiusfunction(result)})

    div {className:"relative"},
      div {className:"absolute"},
        img {src:@props.image}
      div {className:"absolute"},
        svg {width:1382,height:472,viewBox:"0 0 1381.622 472.978", 'enable-background':"new 0 0 1381.622 472.978"},
          g {},
            tokens
          g {},
            statisticsChart
            statisticsChartAverage
      # div {className:"absolute", width:300},
      #   img {src:@props.imageFrame}


Configurator = React.createClass

  getInitialState:->
    {
    currentIndex:0
    currentValue:0
    currentIndexRunning:0
    }

  handleSubmitInitializing:(e)->
    e.preventDefault()
    if not isNaN(parseInt(@state.currentIndex)) and not isNaN(parseInt(@state.currentValue)) and 0 <= parseInt(@state.currentIndex) <@props.statistics.length
      newStats = @props.statistics
      newStats[RouletteModel.order[@state.currentIndex]]=@state.currentValue
      @props.handler(newStats)
      @setState {currentIndex:(@state.currentIndex+1)%%@props.statistics.length,currentValue:''}

  handleSubmitRunning:(e)->
    e.preventDefault()
    if not isNaN(parseInt(@state.currentIndexRunning)) and 0 <= parseInt(@state.currentIndexRunning) <@props.statistics.length
      newStats = @props.statistics
      newStats[@state.currentIndexRunning]=newStats[parseInt(@state.currentIndexRunning)]+1
      @props.handler(newStats)
      # @setState {currentIndexRunning:''}

  onChangeValue: (e)->
    if not isNaN(parseInt(e.target.value)) 
      @setState {currentValue:parseInt(e.target.value)}

  onChangeNumber: (e)->
    if not isNaN(parseInt(e.target.value))
      @setState {currentIndex:RouletteModel.order.indexOf(parseInt(e.target.value))}

  onChangeNumberRunning: (e)->
    if not isNaN(parseInt(e.target.value))
      @setState {currentIndexRunning:parseInt(e.target.value)}

  reset:(e)->
    e.preventDefault()
    @props.handler((Math.floor(10 + 10*Math.random()) for i in [0 .. 36]))

  render:->
    div {className:"configurator"},
      form {onSubmit:@reset},
        "Show me a demo " 
        button {}, "OK"
      form {onSubmit:@handleSubmitInitializing},
        "Number " 
        input {onChange:@onChangeNumber, value:RouletteModel.order[@state.currentIndex]}
        " fell "
        input {onChange:@onChangeValue, value:@state.currentValue}
        " times already "
        button {}, "OK"
      form {onSubmit:@handleSubmitRunning},
        "Number " 
        input {onChange:@onChangeNumberRunning, value:@state.currentIndexRunning}
        " just fell "
        button {}, "OK"

TheRoulette = React.createClass
  getInitialState:->
    {
    # statistics:(Math.floor(10 + 10*Math.random()) for i in [0 .. 36])
    statistics:(0 for i in [0 .. 36])
    }

  changeStatistics:(newStats)->
    @setState {statistics:newStats}

  render:->
    div {className:'rouletteApp'},
      Configurator({handler:@changeStatistics,statistics:@state.statistics})
      Roulette({statistics:@state.statistics})


module.exports = TheRoulette