_ = require 'Underscore'
assert = require 'power-assert'
sinon = require 'sinon'
chai = require 'chai'
chai.should()
expect = chai.expect

Conditioner = require '../src/index'

describe 'Conditioner', ->

  # setup test arguments and instances

  # main class
  c = new Conditioner
    starts: 'who'
    ends: '?'
  ,
    matchWords: false
    escapeValues: true
    ignorePunctuation: false

  # regex tests
  re = new RegExp /test/, 'i'
  reStr = '/test/i'

  describe 'constructor', ->

    it "should have an expressions object", ->
      c.expressions.should.be.instanceof Object

    it "should have a config object", ->
      c.expressions.should.be.instanceof Object

    it "should assume defaults if not given options", ->
      c.config.ignoreCase.should.be.true

    it "should accept options which override defaults", ->
      c.config.matchWords.should.not.be.true

    it "should accept conditions and create regular expressions", ->
      expect( _.size c.expressions ).to.equal 2
      expect( _.isRegExp c.expressions[1] ).to.be.true

  describe '#add()', ->

    it "should add a new condition object and return self", ->
      c = c.add excludes: 'question mark', 'eroteme'
      c.should.be.instanceof Conditioner
      expect( _.size c.expressions ).to.equal 3

    it "should accept a key for passed conditions", ->
      c.expressions.should.have.property 'eroteme'

    it "should accept a regex", ->
      c.add re, 'regex'
      expect( _.size c.expressions ).to.equal 4

    it "should accept a string to convert to regex", ->
      c.add reStr, 'reStr'
      expect( _.size c.expressions ).to.equal 5

  describe '#toRegExp()', ->

    it "should convert a string in regex format to regex", ->
      expect( _.isRegExp c.expressions.regex ).to.be.true
      c.expressions.regex.should.eql re
      expect( _.isRegExp c.expressions.reStr ).to.be.true
      c.expressions.reStr.should.eql re

    it "should throw an error when input cannot be converted to regex", ->
      expect( () -> c.add 'string' ).to.throw Error

  describe '#escapeRegExp()', ->

    it "should escape any special regex characters from a value", ->
      expect( c.escapeRegExp ".+*?^$[]{}()|/" ).to.equal "\\.\\+\\*\\?\\^\\$\\[\\]\\{\\}\\(\\)\\|\\/"

  describe '#create()', ->

    it "should return false when given invalid value", ->
      expect( c.create 'test', {} ).to.be.false

    it "should throw an error when given unrecognised type", ->
      expect( () -> c.create 'test', 'test' ).to.throw Error

    it "should create a regex for a given type and value", ->
      re1 = c.create 'contains', 'test'
      re2 = new RegExp /(test)/, 'i' # NB: matchWords disabled
      expect( _.isRegExp re1 ).to.be.true
      re1.should.eql re2

  describe '#compare()', ->

    it "should return true if all conditions are true", ->
      delete c.expressions.regex
      delete c.expressions.reStr
      expect( c.compare 'Who goes there?' ).to.be.true

    it "should return false if all conditions are false", ->
      expect( c.compare 'Not even close!' ).to.be.false

    it "should return false if any conditions are false", ->
      expect( c.compare 'Who? Tis I!' ).to.be.false

    it "should store results of each condition", ->
      c.compared.should.be.instanceof Object
      expect( _.values c.compared ).to.eql [true,false,true]

  describe '#capture()', ->
    it "should return an object with props for each condition capture group", ->
      c.expressions = {}
      c.config.matchWords = true
      c.add range: '1-9', 'num'
      c.add after: 'name', 'name'
      captured = c.capture 'Test: name Testing, number 1'
      captured.should.eql
        num: '1'
        name: 'Testing'

    it "should store the results of each capture with any given keys", ->
      c.captured.should.eql
        num: '1'
        name: 'Testing'

    it "should return false if nothing was captured", ->
      expect( c.capture 'Test invalid input' ).to.be.false

  describe "#clear()", ->

    it "should clear results but keep expressions for existing conditions", ->
      c.clear()
      expect( c.compared ).to.be.undefined
      expect( c.captured ).to.be.undefined
      expect( c.expressions ).to.be.instanceof Object
      expect( _.size c.expressions ).to.equal 2

  describe '#clearAll()', ->

    it "should clear all expressions and results of compares or captures", ->
      c.clearAll()
      c.expressions.should.eql {}

  strings = [
    'Order me a coffee please'
    'Order 2 coffees for Otis'
    'Get me 100 coffees'
    'Order Borat 10 coffees please... NOT!'
    'Order me a horse, please'
    'I love lamp'
  ]

  describe """use cases : coffee order
    \t#{ strings[0] }
    \t#{ strings[1] }
    \t#{ strings[2] }
    \t#{ strings[3] }
    \t#{ strings[4] }
    \t#{ strings[5] }
  """, ->

    # coffee order tests
    order = new Conditioner()
    	.add starts: 'order|get'
    	.add contains: 'coffee(s)?', 'word'
    	.add excludes: 'not'
    deets = new Conditioner()
      .add contains: 'me', 'forSelf'
    	.add range: '1-999', 'qty'
    	.add after: 'for', 'for'
    	.add ends: 'please', 'polite'

    it ".compare() passes when format is \"Order (or get) coffee(s) ...\"", ->
      expect( order.compare strings[0] ).to.be.true
      expect( order.compare strings[1] ).to.be.true
      expect( order.compare strings[2] ).to.be.true

    it ".compare() fails if contains \"not\", other conditions met", ->
      expect( order.compare strings[3] ).to.be.false
      expect( order.compared ).to.eql
        0: true
        2: false
        word: true

    it ".compare() fails if coffee isn't mentioned, other conditions met", ->
      expect( order.compare strings[4] ).to.be.false
      expect( order.compared ).to.eql
        0: true
        2: true
        word: false

    it ".compare() fails if not at all valid, no conditions met", ->
      expect( order.compare strings[5] ).to.be.false
      expect( order.compared ).to.eql
        0: false
        2: true
        word: false

    it ".capture() can tell if the order is for \"me\"", ->
      deets.capture strings[0]
      expect( deets.captured.forSelf ).to.not.be.undefined

    it ".capture() can get the name from the order if not \"me\"", ->
      deets.capture strings[1]
      expect( deets.captured.forSelf ).to.be.undefined
      deets.captured.for.should.equal "Otis"

    it ".capture() can get the number of coffees in each order (if valid)", ->
      qtys = _.map strings, (str) ->
        if order.compare str then deets.capture(str).qty ? '1' else '0'
      qtys.should.eql [ '1', '2', '100', '0', '0', '0' ]

    it ".capture() can tell if they asked politely", ->
      pls = _.map strings, (str) ->
        if deets.capture(str).polite then yes else no
      pls.should.eql [ true, false, false, false, true, false ]

    it "use case should put it all together", ->
      replies = _.map strings, (str) ->
        detail = deets.capture str
        valid = order.compare str
        word = order.matches.word?[0] ? '?'
        qty = detail.qty ? '1'
        who = if detail.forSelf then "you" else detail.for ? "I dunno?"
        polite = if detail.polite then yes else no
        switch
          when valid and polite
            "#{ qty } #{ word } for #{ who }. Have a nice day :)"
          when valid
            "#{ qty } #{ word } for #{ who }"
          when not valid and polite
            "Sorry, no."
          else
            "No coffee for you."
      replies.should.eql [
        '1 coffee for you. Have a nice day :)'
        '2 coffees for Otis'
        '100 coffees for you'
        'No coffee for you.'
        'Sorry, no.'
        'No coffee for you.'
      ]
