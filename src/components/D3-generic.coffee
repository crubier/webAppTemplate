React = require 'react/addons'
{svg}=React.DOM

# // d3 chart function
# //   note that this is a higher-order function to
# //   allowing passing in the component properties/state
update = (props) ->
  (me) ->
    me
      .attr("cx", 3 + props.r)
      .attr("cy", 3 + props.r)
      .attr("r", props.r)
      .attr("fill", props.color)

MyCircle = React.createClass
  render: () ->
    svg {width:200, height:200}
    
  componentDidMount:  () ->
    d3.select(@getDOMNode()).append("circle").call(update(@props))

  shouldComponentUpdate: (props) ->
    d3.select(@getDOMNode()).select("circle").call(update(@props))
    false