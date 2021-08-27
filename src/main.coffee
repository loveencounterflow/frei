

'use strict'





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
#...........................................................................................................
{ jr }                    = CND
@types                    = require './types'
{ isa
  validate
  cast
  type_of }               = @types
#...........................................................................................................
# DATOM                     = new ( require 'datom' ).Datom { dirty: false, }
# { new_datom
#   lets
#   freeze
#   thaw
#   is_frozen
#   select }                = DATOM.export()
#...........................................................................................................
SP                        = require 'steampipes'
# SP                        = require '../../apps/steampipes'
{ $
  $async
  $drain
  $watch
  $show  }                = SP.export()
#...........................................................................................................
@all_npmnames             = require 'all-the-package-names'
debug '^624^', 'cup' in @all_npmnames

#-----------------------------------------------------------------------------------------------------------
@get_valid_npmchrs = ( position ) ->
  prefix = switch position
    when 'first' then ''
    when 'other' then 'a'
    else throw new Error "^55763^ illegal position #{rpr position}"
  R = ''
  for cid in [ 0x00 .. 0xff ]
    chr = String.fromCodePoint cid
    R += chr if isa._frei_npmname prefix + chr
  return R

#-----------------------------------------------------------------------------------------------------------
@walk_all_possible_names = ( min_chr_count, max_chr_count ) ->
  max_chr_count ?= min_chr_count
  validate.count min_chr_count
  validate.count max_chr_count
  unless min_chr_count <= max_chr_count
    throw new Error "^7763^ min_chr_count must be equal or greater than max_chr_count, got #{min_chr_count}, #{max_chr_count}"
  for count in [ min_chr_count .. max_chr_count ]
    yield from @_walk_all_possible_names count
  return

#-----------------------------------------------------------------------------------------------------------
@_walk_all_possible_names = ( count ) ->
  return if count is 0
  permutation = require 'string-permutation'
  #.........................................................................................................
  if count is 1
    yield chr for chr in @valid_npmchrs.first
    return
  #.........................................................................................................
  tails = permutation @valid_npmchrs.other, { maxSize: count - 1, recursive: false, }
  for chr in @valid_npmchrs.first
    for tail in tails
      yield chr + tail
  #.........................................................................................................
  yield return


#     if count is 1
#       yield first_chr
#       continue
#     for nr in [ 1 .. count ]

#     tail = []
#     #   for
#   return null

#-----------------------------------------------------------------------------------------------------------
@valid_npmchrs =
  first: @get_valid_npmchrs 'first'
  other: @get_valid_npmchrs 'other'
# debug @valid_npmchrs

#-----------------------------------------------------------------------------------------------------------
@f = -> new Promise ( resolve ) =>
  last          = Symbol 'last'
  all_npmnames  = new Set @all_npmnames
  min_chr_count = 2
  max_chr_count = 3
  main_source   = @walk_all_possible_names min_chr_count, max_chr_count
  writer_source = SP.new_push_source()
  output_path   = './free-npm-names.txt'
  ( require 'fs' ).writeFileSync output_path, ''
  #.........................................................................................................
  writer        = []
  writer.push writer_source
  writer.push SP.$as_line()
  writer.push SP.tee_write_to_file_sync output_path
  writer.push $drain()
  SP.pull writer...
  #.........................................................................................................
  main          = []
  main.push main_source
  # main.push SP.$filter ( name ) -> name.length < 2
  # main.push SP.$filter ( name ) -> isa._frei_npmname name
  # main.push SP.$filter ( name ) -> /(.)\1\1/.test name
  # main.push SP.$filter ( name ) -> name.startsWith 'q'
  main.push SP.$filter ( name ) -> not /[._-]/.test name
  main.push SP.$filter ( name ) -> not /[0-9]/.test name
  # main.push SP.$filter ( name ) -> not /^[0-9]/.test name
  main.push SP.$filter ( name ) -> not /^-/.test name
  main.push SP.$filter ( name ) -> not /[._-]$/.test name
  main.push SP.$filter ( name ) -> /^[^aeiou][aeiou].$/.test name
  # main.push SP.$filter ( name ) -> /(^.[aeiou])|(^[aeiou].[aeiou])/.test name
  # main.push SP.$filter ( name ) -> /^[aeiou].[aeiou]/.test name
  main.push SP.$filter ( name ) -> not all_npmnames.has name
  # main.push $ ( d, send ) -> send d.join ''
  # main.push SP.$show()
  main.push SP.$sort()
  main.push $watch { last, }, ( d ) -> return writer_source.end() if d is last; writer_source.send d
  # main.push $watch
  # main.push $drain ( names ) -> resolve names
  main.push $drain()
  SP.pull main...
  #.........................................................................................................
  return null


############################################################################################################
if module is require.main then do =>
  info @all_npmnames.length
  # => 286289
  # seen_names = new Set()
  # for name in @all_npmnames
  #   continue unless name.length < 2
  #   seen_names.add name
  # info [ seen_names..., ].join ' '
  help ( await @f() ).join ' '

  # debug '^776^', [ ( @walk_all_possible_names 3 )... ].join ' '


############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
############################################################################################################
->

  #-----------------------------------------------------------------------------------------------------------
  list_npm_names = ->
    # registry = require '/home/flow/temp/npm-cache.json'
    D                   = require 'pipedreams'
    $                   = D.remit.bind D
    $async              = D.$async.bind D
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

  # #-----------------------------------------------------------------------------------------------------------
  # get_combinator = ( combinations = null ) ->
  #   alphabet      = Array.from 'abcdefghijklmnopqrstuvwxyz'
  #   combinations ?= [ '' ]
  #   for letter in alphabet
  #     for combination in combinations
  #       yield combination + letter
  #   return null



