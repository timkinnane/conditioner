_ = require 'underscore'

# convert sets of semantic key/vale conditions to regex capture groups
# also accepts straight regex or strings to convert to regex
# if an array is given, multiple conditions can be combined
# config determines flags and pre-filtering input
class Conditioner
  constructor: (condition, options={}) ->

    # merge defaults and options to get config
    @config = _.defaults options,
      matchWords: true
      ignoreCase: true
      ignorePunctuation: true
      escapeValues: false
    @b = if @config.matchWords then '\\b' else '' # word boundary capture toggle
    @i = if @config.ignoreCase then 'i' else '' # ignore case flag toggle

    # register expression converter type keys - could be querired or extended
    @types = [
      'is','starts','ends','contains','excludes','after','before','range'
    ]
    # TODO: Use method to register default types allowing extended converters

    # generate expressions from given conditions
    @expressions = {}
    if typeof condition is 'array' # add each condition in array
      @add c for c in condition
    else if typeof condition is 'object' # add each key/val as a condition
      for key,val of condition
        c = {}
        c[key] = val
        @add c
    else if condition? then @add condition # add whatever was given as condition

  # add conditions to compare or capture with, converted if not already regex
  add: (condition, key) ->
    key ?= _.size @expressions # use int index if no named key
    switch
      when _.isRegExp condition
        @expressions[key] = condition
      when typeof condition is 'string'
        @expressions[key] = @toRegExp condition
      when typeof condition is 'object'
        for type, value of condition
          @expressions[key] = @create type, value
    return @ # return self for chaining adds

  # convert strings to regular expressions
  toRegExp: (str) ->
    match = str.match new RegExp '^/(.+)/(.*)$'
    re = new RegExp match[1], match[2] if match
    throw new Error "#{str} can not converted to RegExp" if not _.isRegExp re
    return re

    # var regex = new RegExp('^/(.+)/(.*)$');
    # var match = s.match(regex);
    # if (match) {
    #   return new RegExp(match[1], match[2]);
    # }

  # escape any special regex characters
  escapeRegExp: (str) ->
    str.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"

  # create regex for a value from various condition types
  create: (type, value) ->
    return false unless typeof value is 'string'
    throw new Error "#{type} is an invalid condition type" if type not in @types
    value = @escapeRegExp value if @config.escapeValues
    switch type
      # match the whole thing
      when 'is' then new RegExp "^(#{value})$", @i
      # match the beginning / first word (if matchWords)
      when 'starts' then new RegExp "^(#{value})#{@b}", @i
      # match the end / last word (if matchWords)
      when 'ends' then new RegExp "#{@b}(#{value})$", @i
      # match a part / word (if matchWords)
      when 'contains' then new RegExp "#{@b}(#{value})#{@b}", @i
      # exclude a part / word (if matchWords)
      when 'excludes' then new RegExp "^((?!#{@b}#{value}#{@b}).)*$", @i
      # match anything after value / next word (if matchWords)
      when 'after' then new RegExp "(?:#{value}\\s)([\\w\\-]+)", @i
      # match anything before value / prev word (if matchWords)
      when 'before' then new RegExp "#{@b}([\\w\\-]+)(?:\\s#{value})", @i
      # match a given range - NB: only between 0-999 (otherwise use regexp)
      when 'range' then new RegExp "#{@b}([#{value}]|[#{value}][0-9]|[#{value}][0-9][0-9])#{@b}", @i

  # test a string against stored conditions and config
  # returns successful if all conditions meet
  # each conditions outcome saved to this.compared, for individual checks
  # full match properties can be accessed from this.matches
  compare: (str) ->
    return false if not _.size @expressions # nothing to compare
    str = str.replace /[^\w\s]/g, '' if @config.ignorePunctuation
    @matches = _.mapObject @expressions, (re) -> str.match re
    @compared = _.mapObject @matches, (match) -> match?
    return _.every _.values @compared # true if all truthy

  # extract parts of a string matching conditions
  # returns array of captured parts (also available as this.captured)
  # full match properties can be accessed from this.matches
  capture: (str) ->
    return false if not _.size @expressions # nothing to capture
    str = str.replace /[^\w\s]/g, '' if @config.ignorePunctuation
    @matches = _.mapObject @expressions, (re) -> str.match re
    @captured = _.mapObject @matches, (match) -> match?[1]
    return if _.some @captured then @captured else false # false if none truthy

  # clear results but keep expressions and config
  clear: ->
    delete @captured
    delete @compared
    delete @matches

  #clear expressions too, just keep config
  clearAll: ->
    @clear()
    @expressions = {}

module.exports = Conditioner
