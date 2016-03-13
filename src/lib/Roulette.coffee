
DSP = require './Dsp.coffee'
# http://www.jeu-et-casino.com/regles-roulette.php
allBets = ()->
  rouletteWithoutZeros = ((i+j+1 for i in [0...36] by 3)for j in [0...3])
  rouletteWithZeros = ([0].concat(line) for line in rouletteWithoutZeros)
  
  bets={}

  bets["single0"]={numbers:[0],payout:35,position:{x:0,y:3}}
  # singles
  for i in [1 .. 36]
    bets["single#{i}"]={numbers:[i],payout:35,position:{x:2+2*((i-1)//3),y:5-2*((i-1)%%3)}}

  # horizontal doubles
  for i in [0 ... 12]
    for j in [0 ... 3]
      bets["doubleHorizontal#{i}x#{j}"]={numbers:[ rouletteWithZeros[j][i],rouletteWithZeros[j][i+1] ],payout:17,position:{x:1+2*i,y:1+2*(2-j)}}

  # vertical doubles
  for i in [0 ... 12]
    for j in [0 ... 2]
      bets["doubleVertical#{i}x#{j}"]={numbers:[ rouletteWithoutZeros[j][i],rouletteWithoutZeros[j+1][i] ],payout:17,position:{x:2+2*i,y:2+2*(1-j)}}

  # quadruples
  for i in [0 ... 11]
    for j in [0 ... 2]
      bets["quadruple#{i}x#{j}"]={numbers:[ rouletteWithoutZeros[j][i],rouletteWithoutZeros[j+1][i], rouletteWithoutZeros[j][i+1],rouletteWithoutZeros[j+1][i+1] ],payout:8,position:{x:3+2*i,y:2+2*(1-j)}}

  # four first
  bets["fourFirsts"]={numbers:[0,1,2,3],payout:8,position:{x:1,y:0}}

  # triples with zero
  bets["zeroTriple0"]={numbers:[0,1,2],payout:11,position:{x:1,y:4}}
  bets["zeroTriple1"]={numbers:[0,2,3],payout:11,position:{x:1,y:2}}

  # triples
  for i in [0 ... 12]
    bets["triple#{i}"] = {numbers:(rouletteWithoutZeros[j][i] for j in [0 ... 3]),payout:11,position:{x:2+2*i,y:0}}

  # hexuples
  for i in [0 ... 11]
    bets["hexuples#{i}"]={numbers:[ rouletteWithoutZeros[0][i],rouletteWithoutZeros[1][i],rouletteWithoutZeros[2][i], rouletteWithoutZeros[0][i+1],rouletteWithoutZeros[1][i+1],rouletteWithoutZeros[2][i+1] ],payout:5,position:{x:3+2*i,y:0}}

  # third
  for i in [0 .. 2]
    bets["third#{i}"] = {numbers:(12*i+j+1 for j in [0 ... 12]),payout:2,position:{x:5+8*i,y:6.66}}

  # two third
  for i in [0 ... 2]
    bets["twoThird#{i}"] = {numbers:(12*i+j+1 for j in [0 ... 24]),payout:0.5,position:{x:9+8*i,y:6.66}}

  # row
  for i in [0 .. 2]
    bets["row#{i}"] = {numbers:rouletteWithoutZeros[i],payout:2,position:{x:26,y:5-2*i}}

  # two row
  for i in [0 ... 2]
    bets["twoRow#{i}"] = {numbers:rouletteWithoutZeros[i].concat(rouletteWithoutZeros[i+1]),payout:0.5,position:{x:26,y:4-2*i}}

  # half
  for i in [0 .. 1]
    bets["half#{i}"] = {numbers:(18*i+j+1 for j in [0 ... 18]),payout:1,position:{x:3+20*i,y:7.85}}

  # even and odd
  bets["even"] = {numbers:(i for i in [2 .. 36] by 2),payout:1,position:{x:7,y:7.85}}
  bets["odd"] = {numbers:(i for i in [1 .. 35] by 2),payout:1,position:{x:19,y:7.85}}

  # black and red
  bets["black"] = {numbers:[2,4,6,8,10,11,13,15,17,19,20,22,24,26,29,31,33,35],payout:1,position:{x:15,y:7.85}}
  bets["red"] = {numbers:[1,3,5,7,9,12,14,16,18,21,23,25,27,28,30,32,34,36],payout:1,position:{x:11,y:7.85}}

  return bets

order = [0,26,3,35,12,28,7,29,18,22,9,31,14,20,1,33,16,24,5,10,23,8,30,11,36,13,27,6,34,17,25,2,21,4,19,15,32]



# lets compute it once
# possibleBets = allBets()

# resultStatistics = (Math.floor(10 + 10*Math.random()) for i in [0 .. 36])

# This is how a bet is specified
# bet =
#   single33:1
#   doubleHorizontal11x2:2


# Computes the expectations for each possible bet, considering result statistics
# Coefficient = 0 for optimal gains if you have infinite money, 1 is more reasonable, 2 or more if you don't want to take risks
betExpectation = (resultStatistics,coef=1) ->
  possibleBets = allBets()
  # coefficient=if coefficient? then coefficient else 1
  betExpectedValue = {}
  resultStatisticsSampleNumber = DSP.total resultStatistics
  # console.log "#{resultStatisticsSampleNumber} samples"
  resultProbability = DSP.divide resultStatistics, resultStatisticsSampleNumber
  # console.log resultStatistics
  for betname of possibleBets
    betExpectedValue[betname]=0
    for i in [0 ... resultProbability.length]
      betExpectedValue[betname] += resultProbability[i] * 
        if i in possibleBets[betname].numbers
          possibleBets[betname].payout
        else
          -1

  betExpectations = []
  for betname,betresult of betExpectedValue
    betExpectations.push 
      name:betname
      numbers:possibleBets[betname].numbers
      result:100*betresult
      risk:possibleBets[betname].payout+1
      heuristic:((coefficient=1)->(1000*betresult/((possibleBets[betname].payout+1)**coefficient)))
      # heuristic:((coefficient=1)->(1000*betExpectedValue[betname]/((possibleBets[betname].payout+1)**coefficient)))
      heuristix:(100*betresult/((possibleBets[betname].payout+1)**coef))


  betExpectations.sort((a,b)->(b.heuristic-a.heuristic))

  res = betExpectations.slice(0,10)
  # for bet in res
    # console.log bet
  
  return betExpectations

# Computes the payout of a bet, when the roulette falls on resultnumber
betPayout = (bet,resultnumber) ->
  betresults = {}
  possibleBets = allBets()
  for betname,betvalue of bet
    if possibleBets[betname]? and (resultnumber in possibleBets[betname].numbers)
      betresults[betname]=  betvalue * (possibleBets[betname].payout)
    else
      betresults[betname]=  -1*betvalue
  
  total = 0;
  for betname,betresult of betresults
    total += betresult

  return total
# console.log "#{resultStatistics}"
# console.log betExpectation resultStatistics


# result = Math.floor(Math.random()*37)
# console.log result
# console.log betPayout({"even":2,"single22":1,"red":4},result)


module.exports.betExpectation = betExpectation

module.exports.possibleBets = allBets
module.exports.order = order







