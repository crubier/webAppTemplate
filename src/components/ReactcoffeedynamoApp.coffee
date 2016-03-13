
React = require 'react/addons'
ReactTransitionGroup = React.addons.CSSTransitionGroup
VectorWidget = require './VectorWidget.coffee'
Chart = require './Chart.coffee'

# global css
require '../../styles/reset.css'
require '../../styles/main.css'

imageURL = '../../images/yeoman.png'

{div,img,p,tr,th,td,span,table,thead,tbody,form,input} = React.DOM

ReactcoffeedynamoApp = React.createClass
  getInitialState: ->
    {
      filterText: '',
      inStockOnly: false
    }

  handleUserInput: (filterText, inStockOnly)->
    @setState {
      filterText: filterText,
      inStockOnly: inStockOnly
    }
    undefined
  # handleClick : ->
  #   # console.log @state.data[0].length
  #   # console.log "ReactcoffeedynamoApphandleClick"
  #   # data = @state.data
  #   for serie in @state.data
  #     serie.push [Math.random()*2-0.9 + serie[serie.length-1][0],Math.random()*2-0.9+ serie[serie.length-1][1]]
  #   @setState {data:@state.data}
  #   console.log @state.data[0].length
  #   undefined
  
  render: ->
    console.log (prod.name for prod in @props.products when ((prod.name.indexOf(@state.filterText) isnt -1) and
        (prod.stocked or not @state.inStockOnly)))
        console.log (prod.name for prod in @props.products when (prod.name.indexOf('ball') isnt -1))
    div null,
      img {src:imageURL}
      p null, "hellooo"
      # input {type:"button",onClick:@handleClick},
      #   "Add Point"
      FilterableProductTable {products:@props.products,filterText:@state.filterText,inStockOnly:@state.inStockOnly,handleUserInput:@handleUserInput}
      Chart {data:(prod.data for prod in @props.products when ((prod.name.indexOf(@state.filterText) isnt -1) and
        (prod.stocked or not @state.inStockOnly))),width:800,height:300}
      # div {className:'main'},
      #   VectorWidget null
        # ReactTransitionGroup {transitionName:'fade'},

ProductCategoryRow = React.createClass
  render: ->
    tr null,
      th {colSpan:2},
        @props.category

ProductRow = React.createClass
  render: ->
    tr null,
      td null,
        if @props.product.stocked
          @props.product.name
        else
          span({style:{color:'red'}},@props.product.name)
      td null,(Math.round(100*@props.product.data[@props.product.data.length-1][1])/100)

ProductTable = React.createClass
  render: ->
    rows = []
    lastCategory = null
    for prod in @props.products
      if (
        (prod.name.indexOf(@props.filterText) isnt -1) and
        (prod.stocked or not @props.inStockOnly)
        )
        if prod.category isnt lastCategory
          rows.push(
            ProductCategoryRow {category:prod.category, key:"#{prod.category}"}
          )
        rows.push(
          ProductRow {product:prod,key:"#{prod.category}#{prod.name}"}
        )
        lastCategory = prod.category
    table null,
      thead null,
        tr null,
          th null,"Name"
          th null,"Price"
      tbody null,
        # ReactTransitionGroup {transitionName:'fade',transitionEnter:false,transitionLeave:false},
        rows

SearchBar = React.createClass
  handleChange: ->
    @props.onUserInput(
      @refs.filterTextInput.getDOMNode().value,
      @refs.inStockOnlyInput.getDOMNode().checked
    )
    return
  render: ->
    form null,
      input {
        type:"text",
        placeholder:"Search",
        value:@props.filterText,
        ref:"filterTextInput",
        onChange:@handleChange
      }
      p null,
        input {
          type:"checkbox",
          value:@props.inStockOnly,
          ref:"inStockOnlyInput",
          onChange:@handleChange
        }
        "Only show products in stock"

FilterableProductTable = React.createClass
  render: ->
    div null,
      SearchBar {
        filterText:@props.filterText,
        inStockOnly:@props.inStockOnly,
        onUserInput:@props.handleUserInput
      }
      ProductTable {
        products:@props.products,
        filterText:@props.filterText,
        inStockOnly:@props.inStockOnly
      }


PRODUCTS = [
  {category: 'Sporting Goods', price: '$49.99', stocked: true, name: 'Football',data:(sum=0;(((sum=Math.max(0,sum+Math.random()-0.499));[i*0.001,sum]) for i in [0..360000] ) )}
  {category: 'Sporting Goods', price: '$9.99', stocked: true, name: 'Baseball',data:(sum=0;(((sum=Math.max(0,sum+Math.random()-0.499));[i*0.001,sum]) for i in [0..360000] ) )}
  {category: 'Sporting Goods', price: '$29.99', stocked: false, name: 'Basketball',data:(sum=0;(((sum=Math.max(0,sum+Math.random()-0.499));[i*0.001,sum]) for i in [0..360000] ) )}
  {category: 'Electronics', price: '$99.99', stocked: true, name: 'iPod Touch',data:(sum=0;(((sum=Math.max(0,sum+Math.random()-0.499));[i*0.001,sum]) for i in [0..360000] ) )}
  {category: 'Electronics', price: '$399.99', stocked: false, name: 'iPhone 5',data:(sum=0;(((sum=Math.max(0,sum+Math.random()-0.499));[i*0.001,sum]) for i in [0..360000] ) )}
  {category: 'Electronics', price: '$199.99', stocked: true, name: 'Nexus 7',data:(sum=0;(((sum=Math.max(0,sum+Math.random()-0.499));[i*0.001,sum]) for i in [0..360000] ) )}
]

console.time "firstrender"
React.renderComponent(
  (ReactcoffeedynamoApp {products:PRODUCTS}),
  document.body
)
console.timeEnd "firstrender"

module.exports = ReactcoffeedynamoApp