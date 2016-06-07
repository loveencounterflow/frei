
############################################################################################################
# njs_util                  = require 'util'
PATH                      = require 'path'
FS                        = require 'fs'
OS                        = require 'os'
#...........................................................................................................
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'NPM-NAME-LISTER'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
# suspend                   = require 'coffeenode-suspend'
# step                      = suspend.step
# after                     = suspend.after
# eventually                = suspend.eventually
# immediately               = suspend.immediately
# every                     = suspend.every
#...........................................................................................................
new_json_source           = require 'stream-json'
#...........................................................................................................
S                   = {}
S.max_length        = 4
S.name_pattern      = /^[a-z]+$/
S.registry_route    = PATH.resolve OS.homedir(), '.npm/registry.npmjs.org/-/all/.cache.json'
S.cache_route       = PATH.resolve OS.homedir(), 'temp/npm-cache.json'


#-----------------------------------------------------------------------------------------------------------
list_npm_names = ->
  # registry = require '/home/flow/temp/npm-cache.json'
  D                   = require 'pipedreams'
  $                   = D.remit.bind D
  $async              = D.remit_async.bind D
  json_source         = new_json_source()
  registry_stream     = FS.createReadStream   S.registry_route
  output              = FS.createWriteStream  S.cache_route, 'utf-8'
  #.........................................................................................................
  $pass_module_names = ( S ) =>
    level               = 0
    idx                 = -1
    module_name         = null
    module_nr           = null
    next_string_is_name = no
    #.......................................................................................................
    return $ ( event, send ) =>
      # return if idx > 30
      # send event
      { name, value } = event
      #.....................................................................................................
      switch name
        #...................................................................................................
        when 'startObject'
          level += +1
        #...................................................................................................
        when 'endObject'
          level += -1
        #...................................................................................................
        when 'keyValue'
          if level is 1
            module_nr = parseInt value, 10
            # debug '-->', level, rpr value
          else if ( level is 2 ) and ( value is 'name' )
            next_string_is_name = yes
            idx += +1
            # help '-->', level, rpr value
        #...................................................................................................
        when 'stringValue'
          if next_string_is_name
            module_name         = value
            next_string_is_name = no
            send module_name
            # urge '-->', level, rpr module_name
      #.....................................................................................................
      return null
  #.........................................................................................................
  $pass_short_names = ( S ) =>
    return $ ( name, send ) =>
      send name if name.length <= S.max_length
      #.....................................................................................................
      return null
  #.........................................................................................................
  $pass_valid_names = ( S ) =>
    return $ ( name, send ) =>
      send name if S.name_pattern.test name
      #.....................................................................................................
      return null
  #.........................................................................................................
  $filter_duplicates = ( S ) =>
    names = new Set()
    return $ ( name, send ) =>
      send name unless names.has name
      names.add name
      #.....................................................................................................
      return null
  #.........................................................................................................
  $prepare_output = ( S ) =>
    is_first  = yes
    send_nl   = no
    return $ ( name, send, end ) =>
      #.....................................................................................................
      if is_first
        is_first = no
        send '[\n'
      #.....................................................................................................
      if name?
        if send_nl
          send_nl = no
          send ',\n'
        send JSON.stringify name
        send_nl = yes
      #.....................................................................................................
      if end?
        send '\n]\n'
        end()
      #.....................................................................................................
      return null
  #.........................................................................................................
  registry_stream
    .pipe json_source.input
    .pipe $pass_module_names  S
    .pipe $pass_short_names   S
    .pipe $pass_valid_names   S
    .pipe $filter_duplicates  S
    .pipe D.$show()
    .pipe D.$sort()
    .pipe $prepare_output     S
    .pipe output
  #.........................................................................................................
  return null


#-----------------------------------------------------------------------------------------------------------
find_free_names = ->
  known_names = new Set require S.cache_route
  new_names   = new Set()
  help """
    There are #{known_names.size} names with #{S.max_length} characters or less
    registered with npm."""
  #.........................................................................................................
  names = null
  count = 0
  loop
    count += +1
    break if count > 4
    for name in names = get_combinations names
      # continue unless ( /^[^aeiouy][aeiouy][^aeiouy][aeiouy]$/ ).test name
      # continue unless ( /^[^aeiouy][aeiouy][^aeiouy]$/ ).test name
      # continue unless ( /^kw..$/ ).test name
      # continue unless ( /^cn.$/ ).test name
      # continue unless ( /^fr..$/ ).test name
      continue unless ( /^j[aeiou]?z[aeiou]?r[aeiou]?$/ ).test name
      continue if known_names.has name
      new_names.add name
      echo name
  #.........................................................................................................
  debug new_names.size
  return null

#-----------------------------------------------------------------------------------------------------------
get_combinations = ( combinations = null ) ->
  alphabet      = Array.from 'abcdefghijklmnopqrstuvwxyz'
  # combinations ?= ( '' for letter in alphabet )
  combinations ?= [ '' ]
  R = []
  for letter in alphabet
    for combination in combinations
      R.push letter + combination
  return R

# #-----------------------------------------------------------------------------------------------------------
# get_combinator = ( combinations = null ) ->
#   alphabet      = Array.from 'abcdefghijklmnopqrstuvwxyz'
#   combinations ?= [ '' ]
#   for letter in alphabet
#     for combination in combinations
#       yield combination + letter
#   return null


############################################################################################################
unless module.parent?
  # list_npm_names()
  find_free_names()
  # help words.length
  # debug JSON.stringify words = get_combinations words
  # help words.length
  # debug JSON.stringify words = get_combinations words
  # help words.length
  # debug JSON.stringify words = get_combinations words
  # help words.length

