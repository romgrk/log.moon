-- File: log.moon
-- Author: romgrk
-- Description: printing utils
-- Date: 22 Oct 2015
-- !::moon [.]

local *

-- Array & Strings libraries
_       = require 'moses'
inspect = require 'inspect'
stringx = require 'pl.stringx'
--allen      = require 'allen'
--allen.import() -- extend strings

log = {}

-- Links
ADD  = table.insert
DEL  = table.remove
JOIN = table.concat

CSI   = (n) -> string.char(27) .. "[#{n}m"

STRIP = (s) -> string.gsub(s, '\027%[[^m]*m', '')

class XColor
    @codes:
        blue:      27
        lightblue: 33
        red:       196
        yellow:    226
        green:     34
        purple:    93
        orange:    202
        pink:      201
        cyan:      51
        gray:      238
        white:     255

    new: (ref, @pos=3) => @code = XColor.codes[ref] or ref
    bg: => @pos = 4
    __tostring: => @pos..'8;5;'..@code
class Ansicolor
    @codes:
        default: 9
        black:   0
        red:     1
        green:   2
        yellow:  3
        blue:    4
        purple:  5
        cyan:    6
        grey:    7

    new: (@code=9, @pos=3) =>
    bg: => @pos = 4
    light: => @pos += 6 if @pos < 5
    dark: => @pos -= 6 if @pos > 5
    __tostring: => tostring(@code + 10 * (@pos))
class Attr
    @codes:
        reset:   0
        bold:    1
        dim:     2
        italic:  3
        under:   4
        blink:   5
        reverse: 7
        hidden:  8
        not:     20

    new: (attr) => 
        @flags={attr} 
        @reset=false
        @pos = 1
    __add: (n) => 
        if type(n) != 'number' then n = attibutes[n]
        if n == 0
            @flags = { 0 } 
        elseif n == 20
            @reset = true
        else
            @flags = [ f for f in *@flags when math.abs(f - n) != 20 ]
            table.insert @flags, (if @reset then n + 20 else n)
            @reset = false
        return @
    __tostring: => 
        if @flags and #@flags > 0
            JOIN @flags, ';'
        else
            return ''
-- Terminal style sequence
class StyleNode
    colors  = { n, ( => Ansicolor(c) )         for n, c in pairs Ansicolor.codes }
    xcolors = { n, ( => XColor(c) )            for n, c in pairs XColor.codes }
    formats = { n, ( => Attr(c) )              for n, c in pairs Attr.codes }
    @keys: _.extend {}, xcolors, colors, formats

    -- INSTANCE
    new: (property) =>
        @properties = {}
        ADD(@properties, property) if property
        mt = getmetatable @
        this = mt.__index
        mt.__index = (key) =>
            return this(@, key) if type(this) =='function'

            properties = rawget(@, 'properties')
            len = if properties then #properties else 0

            -- If the current node style has the key, call it
            if len > 0 and properties[1][key] 
                prop = properties[1] 
                func = prop[key]
                func(prop)
                return @

            -- Otherwise, check if it is available on global style nodes
            if handler = StyleNode.keys[key] 
                return @ + handler(@)

            val = this[key]
            if type(val) == 'function'
                return _.bind val, @
            else
                return val
        -- Eof metatable

    xcolor: (ref) =>
        return @ + XColor(ref)

    -- Add property
    __add:    (prop) =>
        ADD @properties, 1, prop
        return @

    -- Return style-escaped string
    __call:   (...) => 
        tostring(@) .. log.string(...) .. CSI(0)
    __concat: (val) => tostring(@) .. tostring(val)

    -- Return escape sequence
    __tostring:     =>
        tokens = {}
        positions = {} 
        for i, prop in ipairs(@properties)
            unless positions[prop.pos]
                positions[prop.pos] = prop
                ADD tokens, tostring(prop)
            else
                DEL @properties, i
        txt = CSI _.join(tokens, ';') 
        return txt

log.Attr      = Attr
log.XColor    = XColor
log.Ansicolor = Ansicolor
log.StyleNode = StyleNode

log.CSI = CSI
log.RST = CSI(0)

-- SETTINGS:
log._width    = 80
log._height   = 24
log.useColors = true

log.string = (...) ->
    strs = _.map {...}, (k, v) -> tostring(v)
    if type(strs)!='table' or strs.__tostring
        return tostring strs
    else
        return table.concat(strs, ' ')
log.print = (...) ->
    strs = _.map {...}, (k, v) -> tostring(v)
    if type(strs)!='table' or strs.__tostring
        print tostring(strs) .. log.RST
    else
        print table.concat(strs, '') .. log.RST
log.write = (...) ->
    io.write(...)

log.xcolor = (c) ->
    xc = XColor(c)
    return StyleNode( xc )

metalog = {}
metalog.__index = (table, key) ->
    if key == 'width' 
        if w = os.getenv('COLUMNS')
            return tonumber(w)
        return log._width
    if key == 'height' 
        if h = os.getenv('LINES')
            return tonumber(h)
        return log._height
    if style = StyleNode.keys[key]
        s = StyleNode( style() )
        return s
    
    return table[key]
metalog.__call = (table, ...) ->
    if log.useColors
        log.pp(...)
    else
        log.print(...)

setmetatable(log, metalog)

log.text = (...) ->
    log.print CSI('0'), ...
log.success = (...) ->
    log.print CSI('40;38;5;46'), ...
log.info = (...) ->
    log.print CSI('40;38;5;33'), ...
log.debug = (...) ->
    log.print CSI('40;38;5;226'), ...
log.warn = (...) ->
    log.print CSI('40;38;5;202'), ...
log.err = (...) ->
    log.print CSI('40;38;5;196'), ...
log.special = (...) ->
    log.print CSI('40;38;5;198'), ...

local pp
local bit
local hex

-- Hex printing

hex = {}
hex.dump = (fs, ...) ->
    local co, width, block, b_size
    args = {...}
    if #args and type(args[1])=='number'
        width = args[1]
    else if log.width and type(log.width)=='number'
        width = log.width
    else
        width = 80
    b_size = math.floor((width - 4) / 4)
    if type(fs) == 'userdata'
        co = coroutine.create ->
            while true
                chunk = fs\read(b_size)
                coroutine.yield(chunk)
            coroutine.yield(false)
    else
        co = coroutine.create ->
            while b_size < #fs
                start = string.sub(fs, 1, b_size)
                fs = string.sub(fs, b_size+1)
                coroutine.yield(start)
            coroutine.yield(fs)
    block = ->
        code, res = coroutine.resume(co)
        return res
    while true do
        bytes = block()
        if not bytes then break
        for b in string.gfind(bytes, ".") do
            log.write(log.blue .. string.format("%02X ", string.byte(b)))
        log.write(log.reset .. string.rep("   ", b_size - string.len(bytes) + 1))
        str = string.gsub(bytes, "%c", ".")
        str = string.gsub(str, "\n", ".")
        log.write(str, "\n")

setmetatable hex, 
    __call: (table, ...) -> 
        arg = { ... }
        typ = type(arg[1])
        if typ=='number'
            return log.blue string.format("%02X ", arg[1])
        if typ=='string' and #arg[1] == 1
            return log.blue string.format("%02X ", string.byte(arg[1]))
        else
            hex.dump(...)

-- Bit printing

bit = {}
bit.dump = (num, pad=0) ->
    sb = ''
    while num>0 do
        rest = num % 2
        sb = tostring(rest) .. sb
        num = (num-rest)/2
    if #sb < pad
        sb = string.rep('0', pad - #sb) .. sb
    return sb

setmetatable bit, 
    __call: (table, ...) -> 
        s = bit.dump(...)
        s = pp.colorize 'number', s if log.useColors
        log.print s

-- SECTION: Pretty printer

pp = {}

local quote, quote2, dquote, dquote2 
local obracket, cbracket, obrace, cbrace, comma, equals, controls

stringEscape = (c) -> controls[string.byte(c, 1)]

pp.theme =
    property: "38;5;253",
    braces: "38;5;247",
    sep: "38;5;240",
    nil: "38;5;244",
    comment: "38;5;246",
    boolean: "38;5;220", -- yellow-orange
    number: "38;5;202", -- orange
    string: "38;5;34",  -- darker green
    quotes: "38;5;40",  -- green
    escape: "38;5;46",  -- bright green
    function: "38;5;129", -- purple
    thread: "38;5;199", -- pink
    table: "38;5;27",  -- blue
    userdata: "38;5;39",  -- blue2
    cdata: "38;5;69",  -- teal
    err: "38;5;196", -- bright red
    success: "38;5;120;48;5;22",  -- bright green on dark green
    failure: "38;5;215;48;5;52",  -- bright red on dark red
    highlight: "38;5;45;48;5;236",  -- bright teal on dark grey
-- Theme proxy -- returns pp.them, but escaped for terminal
theme = setmetatable {},
    __index: (key) =>
        return CSI(pp.theme[key] or 0)

pp.color = (colorName) -> 
    CSI(pp.theme[colorName] or '0')
pp.colorize = (colorName, string, resetName) ->
    if log.useColors
        return (pp.color(colorName) .. tostring(string) .. pp.color(resetName))
    else
        return tostring(string)
pp.special =
    [7]: 'a',
    [8]: 'b',
    [9]: 't',
    [10]: 'n',
    [11]: 'v',
    [12]: 'f',
    [13]: 'r'
pp.loadColors = () ->
    quote    = pp.colorize('quotes', "'", 'string')
    quote2   = pp.colorize('quotes', "'")
    dquote   = pp.colorize('quotes', '"', 'string')
    dquote2  = pp.colorize('quotes', '"')
    obrace   = pp.colorize('braces', '{ ')
    cbrace   = pp.colorize('braces', '}')
    obracket = pp.colorize('property', '[')
    cbracket = pp.colorize('property', ']')
    comma    = pp.colorize('sep', ', ')
    equals   = pp.colorize('sep', ' = ')

    controls = {}
    for i = 0, 31
        c = pp.special[i]
        if not c
            if i < 10
                c = "00" .. tostring(i)
            else
                c = "0" .. tostring(i)
        controls[i] = pp.colorize('escape', '\\' .. c, 'string')
    controls[92] = pp.colorize('escape', '\\\\', 'string')
    controls[34] = pp.colorize('escape', '\\"', 'string')
    controls[39] = pp.colorize('escape', "\\'", 'string')
    for i = 128, 255
        local c
        if i < 100 
            c = "0" .. tostring(i)
        else
            c = tostring(i)
        controls[i] = pp.colorize('escape', '\\' .. c, 'string')
pp.dump = (value, recurse, nocolor) ->
    local seen, output, offset, stack
    seen = {}
    output = {}
    offset = 0
    stack = {}
    recalcOffset = (index) ->
        for i = index + 1, #output 
            m = string.match(output[i], "\n([^\n]*)$")
            if m then
                offset = #(STRIP(m))
            else
                offset = offset + #(STRIP(output[i]))
    write = (text, length) ->
        length = #(STRIP(text)) if not length
        -- Create room for data by opening parent blocks
        -- Start at the root and go down.
        local i
        i = 1
        while offset + length > log.width and stack[i]
            local entry
            entry = stack[i]
            if not entry.opened
                entry.opened = true
                table.insert(output, entry.index + 1, "\n" .. string.rep("  ", i))
                -- Recalculate the offset
                recalcOffset(entry.index)
                -- Bump the index of all deeper entries
                for j = i + 1, #stack
                    stack[j].index = stack[j].index + 1
            i = i + 1
        output[#output + 1] = text
        offset = offset + length
        if offset > log.width 
            return pp.dump(stack)
    indent = () ->
        stack[#stack + 1] =             
            index:  #output,
            opened: false

    unindent = () ->
        stack[#stack] = nil
    process = (localValue) ->
        typ = type(localValue)
        if typ == 'string' 
            if string.match(localValue, "'") and not string.match(localValue, '"') 
                write(dquote .. string.gsub(localValue, '[%c\\\128-\255]', stringEscape) .. dquote2)
            else
                write(quote .. string.gsub(localValue, "[%c\\'\128-\255]", stringEscape) .. quote2)
        elseif typ == 'table' and not seen[localValue] 
            seen[localValue] = true if not recurse
            write(obrace)
            local i, total
            i = 1
            -- Count the number of keys so we know when to stop adding commas
            total = 0
            total = total + 1 for _ in pairs(localValue)
            nextIndex = 1
            for k, v in pairs(localValue)
                indent()
                if k == nextIndex 
                    -- if the key matches the last numerical index + 1
                    -- This is how lists print without keys
                    nextIndex = k + 1
                    process(v)
                else
                    if type(k) == "string" and string.find(k,"^[%a_][%a%d_]*$") 
                        write(pp.colorize("property", k) .. equals)
                    else
                        write(obracket)
                        process(k)
                        write(cbracket .. equals)
                    if type(v) == "table" 
                        process(v)
                    else
                        indent()
                        process(v)
                        unindent()
                if i < total 
                    write(comma)
                else
                    write(" ")
                i = i + 1
                unindent()
            write(cbrace)
        else
            write(pp.colorize(typ, tostring(localValue)))

    process(value)
    s = table.concat(output, "")
    return nocolor and STRIP(s) or s

pp.prettyPrint = (...) ->
    n = select('#', ...)
    arguments = { ... }
    for i = 1, n 
        arguments[i] = pp.dump(arguments[i])
    log.print(table.concat(arguments, "\t"))

setmetatable pp, 
    __call: (table, ...) -> pp.prettyPrint(...)

pp.loadColors()

dumpAST = (value) ->
    local seen, output, offset, stack
    seen = {}
    output = {}
    offset = 0
    stack = {}
    recalcOffset = (index) ->
        for i = index + 1, #output 
            m = string.match(output[i], "\n([^\n]*)$")
            if m then
                offset = #(STRIP(m))
            else
                offset = offset + #(STRIP(output[i]))
    write = (text, length) ->
        length = #(STRIP(text)) if not length
        -- Create room for data by opening parent blocks
        -- Start at the root and go down.
        local i
        i = 1
        while offset + length > log.width and stack[i]
            local entry
            entry = stack[i]
            if not entry.opened
                entry.opened = true
                table.insert(output, entry.index + 1, "\n" .. string.rep("  ", i))
                -- Recalculate the offset
                recalcOffset(entry.index)
                -- Bump the index of all deeper entries
                for j = i + 1, #stack
                    stack[j].index = stack[j].index + 1
            i = i + 1
        output[#output + 1] = text
        offset = offset + length
        if offset > log.width 
            return pp.dump(stack)
    indent = () ->
        stack[#stack + 1] =             
            index:  #output,
            opened: false

    unindent = () ->
        stack[#stack] = nil
    process = (localValue) ->
        typ = type(localValue)
        if typ == 'string' 
            if string.match(localValue, "'") and not string.match(localValue, '"') 
                write(dquote .. string.gsub(localValue, '[%c\\\128-\255]', stringEscape) .. dquote2)
            else
                write(quote .. string.gsub(localValue, "[%c\\'\128-\255]", stringEscape) .. quote2)
        elseif typ == 'table'
            local tag
            tag = localValue.tag 
            write log.lightblue .. tag if tag
            write(obrace)
            local i, total
            i = 1
            -- Count the number of keys so we know when to stop adding commas
            total = 0
            total = total + 1 for _ in ipairs(localValue)
            nextIndex = 1
            for k, v in ipairs(localValue)
                indent()
                if k == nextIndex 
                    -- if the key matches the last numerical index + 1
                    -- This is how lists print without keys
                    nextIndex = k + 1
                    process(v)
                else
                    if type(k) == "string" and string.find(k,"^[%a_][%a%d_]*$") 
                        write(pp.colorize("property", k) .. equals)
                    else
                        write(obracket)
                        process(k)
                        write(cbracket .. equals)
                    if type(v) == "table" 
                        process(v)
                    else
                        indent()
                        process(v)
                        unindent()
                if i < total 
                    write(comma)
                else
                    write(" ")
                i = i + 1
                unindent()
            write(cbrace)
        else
            write(pp.colorize(typ, tostring(localValue)))

    process(value)
    s = table.concat(output, "")
    return nocolor and STRIP(s) or s

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

-- Bindings
log._   = _
log.log = log

-- Inspect
log.inspect = inspect
log.detail = (o, depth=2) -> log.print inspect(o, {:depth})
log.ins1 = (o) -> inspect(o, {depth: 1})
log.ins2 = (o) -> inspect(o, {depth: 2})
log.ins3 = (o) -> inspect(o, {depth: 3})

-- Numbers
log.bit = bit
log.hex = hex

-- Pretty
log.pp = pp
log.theme = theme
log.colorize = pp.colorize

log.dump     = pp.dump
log.dumpAST  = dumpAST
log.printAST = (ast, ...) ->
    log.print dumpAST ast, ...

-- Separators
center = (str, width, char) ->
    strwidth = string.len str
    fillwidth = width - strwidth
    left  = string.rep char, math.floor(fillwidth/2)
    right = string.rep char, math.ceil(fillwidth/2)
    return left .. str .. right

log.title = (msg, c) ->
    unless log.useColors 
        log.print center "[ #{msg} ]", log.width, '='
        return
    c or= theme.comment
    _msg = STRIP msg
    str = c .. center "[ #{_msg} ]", log.width, '='
    str = string.gsub str, _msg, (msg .. c) if #msg != #_msg
    log.print str
log.subtitle = (msg, c) ->
    len = string.len(STRIP msg)
    c or= CSI('38;5;242')
    c = log.useColors and c or ''
    fill = string.rep '-', log.width-len
    log.print msg .. c .. fill
log.comment = (s) -> pp.colorize 'comment', s

return log

