Conditioner = require "./index"

# determine replies to an array of coffee (or possibly not) orders
replyToOrders = (orders) ->

  # order conditions for validity
  validity = new Conditioner()
    .add starts: 'order|get'
    .add contains: 'coffee(s)?', 'coffeePlural'
    .add excludes: 'not'

  # order details
  deets = new Conditioner()
    .add contains: 'me', 'forSelf'
    .add range: '1-999', 'qty'
    .add after: 'for', 'for'
    .add ends: 'please', 'polite'

  orders.map (order) ->
    detail = deets.capture order # capture details
    valid = validity.compare order # test validity

    # get parts
    coffeePlural = validity.matches.coffeePlural?[0] # coffee, coffees or undefined
    qty = detail.qty ? '1'
    who = if detail.forSelf then "you" else detail.for ? "I dunno?"
    polite = if detail.polite then yes else no

    # compose
    switch
      when valid and polite
        "#{ qty } #{ coffeePlural } for #{ who }. Have a nice day :)"
      when valid
        "#{ qty } #{ coffeePlural } for #{ who }"
      when not valid and polite
        "Sorry, no."
      else
        "No coffee for you."

# coffee orders, input received
orders = [
  'Order me a coffee please'
  'Order 2 coffees for Otis'
  'Get me 100 coffees'
  'Order Borat 10 coffees please... NOT!'
  'Order me a horse, please'
  'I love lamp'
]

console.log replyToOrders orders

###
Outputs:
[ '1 coffee for you. Have a nice day :)',
  '2 coffees for Otis',
  '100 coffees for you',
  'No coffee for you.',
  'Sorry, no.',
  'No coffee for you.' ]
###
