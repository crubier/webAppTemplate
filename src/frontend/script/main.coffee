ArrayUtils = require 'lib/ArrayUtils.coffee'
Roulette = require 'components/Roulette.coffee'
React = require 'react'


# model = new TodoModel('react-todos')

render = () ->
  React.renderComponent(
    Roulette({path:''}),
    document.getElementById('app')
  )

# model.subscribe(render)
console.time "ee"
render()
console.timeEnd "ee"