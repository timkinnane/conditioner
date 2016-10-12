![Conditioner - Regex in a bottle](https://raw.githubusercontent.com/timkinnane/conditioner/master/assets/logo.png)

[![NPM version][npm-image]][npm-url]]

> NB: This is a beta release, features are stable but documentation and coverage is incomplete.

## What it do?

Conditioner provides semantic conditions for string comparison and capture.

It isn't intended to replace the full power of regex, just simplify it for some
common use cases.

It was developed specifically for messanging and chat-bot scripts, to compare conversational streams against listeners and capture user inputs with easy to reference keys.

## Installation

`npm install conditioner-regex --save`

---

## Options / Defaults

### `matchWords: true`

Only whole words are matched, so words like "whoever" won't trigger false positives if "who" is what we're looking for.

### `ignoreCase: true`

Conditions are case insensitive by default

### `ignorePunctuation: true`

Punctuation is stripped from inputs by default, so that messages like "Hello World!" and "hello, world" can be treated equally.

### `escapeValues: false`

By default, conditions won't escape special characters, so regex can be used within conditions to enhance capturing.

e.g. `contains: 'coffee(s)?'` will match "A coffee" and "1000 coffees".

Set to true if you actually need to match against special characters.

## Condition Types

- `is` matches the entire string
- `starts` matches the start
- `ends` matches the end
- `contains` matches a segment
- `excludes` negative match a segment
- `after` matches following a segment
- `before` matches preceding segment
- `range` matches a number range

---

## Usage

> NB: It's written in coffee-script so that's what I use in demos, however the dist is compiled to js

Require the module. `Conditioner = require 'conditioner-regex'`

### `new Conditioner( conditions, options )`

Create a Conditioner object with some conditions. e.g.

```coffeescript
c = new Conditioner
  starts: 'who'
  ends: '?'
,
  escapeValues: true
  ignorePunctuation: false
```

Would match any string that *starts* with "who" and *ends* in a question mark.

Conditions can be passed as an array or an object.

### `.add( condition[, key] )`

Adds further conditions and can be chained on the constructor.
You can also add regex objects or strings containing regex patterns as conditions.

```coffeescript
re = new RegExp /test/, 'i'
c.add re, 'regexp'
c.add /test/i, 'regexpString'
c.add is: 'test', 'regexpCondition'
```

The above creates three identical conditions, match results can be accessed by their keys.

### `.expressions`

Object keeping passed conditions, each converted to regex.

### `.compare( string )`

Compares the string against *all* loaded conditions. e.g. Looking for _"Who... ?"_

```coffeescript
c.compare 'Who goes there?'
# returns true

c.compare 'Who? Tis I!'
# returns false
```

### `.capture( string )`

Captures and returns the parts of the string that match each condition. e.g.

```coffeescript
c = new Conditioner
  after: "name is"
  range: "1-99"

c.capture "My name is Isaac, I'm 72"
# returns { 0: 'Isaac', 1: '72' }
```

### `.compared` and `.captured`

Keeps the results of each condition for the last comparison/capture.

### `.matches`

Keeps the full returned results for a standard regex match

### `.clear()`

Clears the compare or capture results, leaving existing conditions.

### `.clearAll()`

Clears results and conditions.

---

## Full Example (uses underscore)

```coffeescript
# coffee orders, input received
strings = [
  'Order me a coffee please'
  'Order 2 coffees for Otis'
  'Get me 100 coffees'
  'Order Borat 10 coffees please... NOT!'
  'Order me a horse, please'
  'I love lamp'
]

# coffee order and details conditions
order = new Conditioner()
  .add starts: 'order|get'
  .add contains: 'coffee(s)?', 'word'
  .add excludes: 'not'
deets = new Conditioner()
  .add contains: 'me', 'forSelf'
  .add range: '1-999', 'qty'
  .add after: 'for', 'for'
  .add ends: 'please', 'polite'

# determine reply
replies = _.map strings, (str) ->
  detail = deets.capture str # capture details
  valid = order.compare str # test validity

  # get reply parts
  word = order.matches.word?[0] ? '?'
  qty = detail.qty ? '1'
  who = if detail.forSelf then "you" else detail.for ? "I dunno?"
  polite = if detail.polite then yes else no

  # compose replies
  switch
    when valid and polite
      "#{ qty } #{ word } for #{ who }. Have a nice day :)"
    when valid
      "#{ qty } #{ word } for #{ who }"
    when not valid and polite
      "Sorry, no."
    else
      "No coffee for you."

# outputs
console.log replies
# ==
# [
#   '1 coffee for you. Have a nice day :)'
#   '2 coffees for Otis'
#   '100 coffees for you'
#   'No coffee for you.'
#   'Sorry, no.'
#   'No coffee for you.'
# ]
```

---

Download and open /docs for docco generated code comments for further detail.

[npm-url]: https://npmjs.org/package/conditioner-regex
[npm-image]: http://img.shields.io/npm/v/conditioner-regex.svg?style=flat
