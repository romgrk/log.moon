local _, inspect, stringx, log, ADD, DEL, JOIN, CSI, STRIP, XColor, Ansicolor, Attr, StyleNode, metalog, hex, bit, pp, stringEscape, theme, dumpAST, center
_ = require('moses')
inspect = require('inspect')
stringx = require('pl.stringx')
log = { }
ADD = table.insert
DEL = table.remove
JOIN = table.concat
CSI = function(n)
  return string.char(27) .. "[" .. tostring(n) .. "m"
end
STRIP = function(s)
  return string.gsub(s, '\027%[[^m]*m', '')
end
do
  local _base_0 = {
    bg = function(self)
      self.pos = 4
    end,
    __tostring = function(self)
      return self.pos .. '8;5;' .. self.code
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, ref, pos)
      if pos == nil then
        pos = 3
      end
      self.pos = pos
      self.code = XColor.codes[ref] or ref
    end,
    __base = _base_0,
    __name = "XColor"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.codes = {
    blue = 27,
    lightblue = 33,
    red = 196,
    yellow = 226,
    green = 34,
    purple = 93,
    orange = 202,
    pink = 201,
    cyan = 51,
    gray = 238,
    white = 255
  }
  XColor = _class_0
end
do
  local _base_0 = {
    bg = function(self)
      self.pos = 4
    end,
    light = function(self)
      if self.pos < 5 then
        self.pos = self.pos + 6
      end
    end,
    dark = function(self)
      if self.pos > 5 then
        self.pos = self.pos - 6
      end
    end,
    __tostring = function(self)
      return tostring(self.code + 10 * (self.pos))
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, code, pos)
      if code == nil then
        code = 9
      end
      if pos == nil then
        pos = 3
      end
      self.code, self.pos = code, pos
    end,
    __base = _base_0,
    __name = "Ansicolor"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.codes = {
    default = 9,
    black = 0,
    red = 1,
    green = 2,
    yellow = 3,
    blue = 4,
    purple = 5,
    cyan = 6,
    grey = 7
  }
  Ansicolor = _class_0
end
do
  local _base_0 = {
    __add = function(self, n)
      if type(n) ~= 'number' then
        n = attibutes[n]
      end
      if n == 0 then
        self.flags = {
          0
        }
      elseif n == 20 then
        self.reset = true
      else
        do
          local _accum_0 = { }
          local _len_0 = 1
          local _list_0 = self.flags
          for _index_0 = 1, #_list_0 do
            local f = _list_0[_index_0]
            if math.abs(f - n) ~= 20 then
              _accum_0[_len_0] = f
              _len_0 = _len_0 + 1
            end
          end
          self.flags = _accum_0
        end
        table.insert(self.flags, ((function()
          if self.reset then
            return n + 20
          else
            return n
          end
        end)()))
        self.reset = false
      end
      return self
    end,
    __tostring = function(self)
      if self.flags and #self.flags > 0 then
        return JOIN(self.flags, ';')
      else
        return ''
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, attr)
      self.flags = {
        attr
      }
      self.reset = false
      self.pos = 1
    end,
    __base = _base_0,
    __name = "Attr"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.codes = {
    reset = 0,
    bold = 1,
    dim = 2,
    italic = 3,
    under = 4,
    blink = 5,
    reverse = 7,
    hidden = 8,
    ["not"] = 20
  }
  Attr = _class_0
end
do
  local colors, xcolors, formats
  local _base_0 = {
    xcolor = function(self, ref)
      return self + XColor(ref)
    end,
    __add = function(self, prop)
      ADD(self.properties, 1, prop)
      return self
    end,
    __call = function(self, ...)
      return tostring(self) .. log.string(...) .. CSI(0)
    end,
    __concat = function(self, val)
      return tostring(self) .. tostring(val)
    end,
    __tostring = function(self)
      local tokens = { }
      local positions = { }
      for i, prop in ipairs(self.properties) do
        if not (positions[prop.pos]) then
          positions[prop.pos] = prop
          ADD(tokens, tostring(prop))
        else
          DEL(self.properties, i)
        end
      end
      local txt = CSI(_.join(tokens, ';'))
      return txt
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, property)
      self.properties = { }
      if property then
        ADD(self.properties, property)
      end
      local mt = getmetatable(self)
      local this = mt.__index
      mt.__index = function(self, key)
        if type(this) == 'function' then
          return this(self, key)
        end
        local properties = rawget(self, 'properties')
        local len
        if properties then
          len = #properties
        else
          len = 0
        end
        if len > 0 and properties[1][key] then
          local prop = properties[1]
          local func = prop[key]
          func(prop)
          return self
        end
        do
          local handler = StyleNode.keys[key]
          if handler then
            return self + handler(self)
          end
        end
        local val = this[key]
        if type(val) == 'function' then
          return _.bind(val, self)
        else
          return val
        end
      end
    end,
    __base = _base_0,
    __name = "StyleNode"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  do
    local _tbl_0 = { }
    for n, c in pairs(Ansicolor.codes) do
      _tbl_0[n] = (function(self)
        return Ansicolor(c)
      end)
    end
    colors = _tbl_0
  end
  do
    local _tbl_0 = { }
    for n, c in pairs(XColor.codes) do
      _tbl_0[n] = (function(self)
        return XColor(c)
      end)
    end
    xcolors = _tbl_0
  end
  do
    local _tbl_0 = { }
    for n, c in pairs(Attr.codes) do
      _tbl_0[n] = (function(self)
        return Attr(c)
      end)
    end
    formats = _tbl_0
  end
  self.keys = _.extend({ }, xcolors, colors, formats)
  StyleNode = _class_0
end
log.Attr = Attr
log.XColor = XColor
log.Ansicolor = Ansicolor
log.StyleNode = StyleNode
log.CSI = CSI
log.RST = CSI(0)
log._width = 80
log._height = 24
log.useColors = true
log.string = function(...)
  local strs = _.map({
    ...
  }, function(k, v)
    return tostring(v)
  end)
  if type(strs) ~= 'table' or strs.__tostring then
    return tostring(strs)
  else
    return table.concat(strs, ' ')
  end
end
log.print = function(...)
  local strs = _.map({
    ...
  }, function(k, v)
    return tostring(v)
  end)
  if type(strs) ~= 'table' or strs.__tostring then
    return print(tostring(strs) .. log.RST)
  else
    return print(table.concat(strs, '') .. log.RST)
  end
end
log.write = function(...)
  return io.write(...)
end
log.xcolor = function(c)
  local xc = XColor(c)
  return StyleNode(xc)
end
metalog = { }
metalog.__index = function(table, key)
  if key == 'width' then
    do
      local w = os.getenv('COLUMNS')
      if w then
        return tonumber(w)
      end
    end
    return log._width
  end
  if key == 'height' then
    do
      local h = os.getenv('LINES')
      if h then
        return tonumber(h)
      end
    end
    return log._height
  end
  do
    local style = StyleNode.keys[key]
    if style then
      local s = StyleNode(style())
      return s
    end
  end
  return table[key]
end
metalog.__call = function(table, ...)
  if log.useColors then
    return log.pp(...)
  else
    return log.print(...)
  end
end
setmetatable(log, metalog)
log.text = function(...)
  return log.print(CSI('0'), ...)
end
log.success = function(...)
  return log.print(CSI('40;38;5;46'), ...)
end
log.info = function(...)
  return log.print(CSI('40;38;5;33'), ...)
end
log.debug = function(...)
  return log.print(CSI('40;38;5;226'), ...)
end
log.warn = function(...)
  return log.print(CSI('40;38;5;202'), ...)
end
log.err = function(...)
  return log.print(CSI('40;38;5;196'), ...)
end
log.special = function(...)
  return log.print(CSI('40;38;5;198'), ...)
end
local pp
local bit
local hex
hex = { }
hex.dump = function(fs, ...)
  local co, width, block, b_size
  local args = {
    ...
  }
  if #args and type(args[1]) == 'number' then
    width = args[1]
  else
    if log.width and type(log.width) == 'number' then
      width = log.width
    else
      width = 80
    end
  end
  b_size = math.floor((width - 4) / 4)
  if type(fs) == 'userdata' then
    co = coroutine.create(function()
      while true do
        local chunk = fs:read(b_size)
        coroutine.yield(chunk)
      end
      return coroutine.yield(false)
    end)
  else
    co = coroutine.create(function()
      while b_size < #fs do
        local start = string.sub(fs, 1, b_size)
        fs = string.sub(fs, b_size + 1)
        coroutine.yield(start)
      end
      return coroutine.yield(fs)
    end)
  end
  block = function()
    local code, res = coroutine.resume(co)
    return res
  end
  while true do
    local bytes = block()
    if not bytes then
      break
    end
    for b in string.gfind(bytes, ".") do
      log.write(log.blue .. string.format("%02X ", string.byte(b)))
    end
    log.write(log.reset .. string.rep("   ", b_size - string.len(bytes) + 1))
    local str = string.gsub(bytes, "%c", ".")
    str = string.gsub(str, "\n", ".")
    log.write(str, "\n")
  end
end
setmetatable(hex, {
  __call = function(table, ...)
    local arg = {
      ...
    }
    local typ = type(arg[1])
    if typ == 'number' then
      return log.blue(string.format("%02X ", arg[1]))
    end
    if typ == 'string' and #arg[1] == 1 then
      return log.blue(string.format("%02X ", string.byte(arg[1])))
    else
      return hex.dump(...)
    end
  end
})
bit = { }
bit.dump = function(num, pad)
  if pad == nil then
    pad = 0
  end
  local sb = ''
  while num > 0 do
    local rest = num % 2
    sb = tostring(rest) .. sb
    num = (num - rest) / 2
  end
  if #sb < pad then
    sb = string.rep('0', pad - #sb) .. sb
  end
  return sb
end
setmetatable(bit, {
  __call = function(table, ...)
    local s = bit.dump(...)
    if log.useColors then
      s = pp.colorize('number', s)
    end
    return log.print(s)
  end
})
pp = { }
local quote, quote2, dquote, dquote2
local obracket, cbracket, obrace, cbrace, comma, equals, controls
stringEscape = function(c)
  return controls[string.byte(c, 1)]
end
pp.theme = {
  property = "38;5;253",
  braces = "38;5;247",
  sep = "38;5;240",
  ["nil"] = "38;5;244",
  comment = "38;5;246",
  boolean = "38;5;220",
  number = "38;5;202",
  string = "38;5;34",
  quotes = "38;5;40",
  escape = "38;5;46",
  ["function"] = "38;5;129",
  thread = "38;5;199",
  table = "38;5;27",
  userdata = "38;5;39",
  cdata = "38;5;69",
  err = "38;5;196",
  success = "38;5;120;48;5;22",
  failure = "38;5;215;48;5;52",
  highlight = "38;5;45;48;5;236"
}
theme = setmetatable({ }, {
  __index = function(self, key)
    return CSI(pp.theme[key] or 0)
  end
})
pp.color = function(colorName)
  return CSI(pp.theme[colorName] or '0')
end
pp.colorize = function(colorName, string, resetName)
  if log.useColors then
    return (pp.color(colorName) .. tostring(string) .. pp.color(resetName))
  else
    return tostring(string)
  end
end
pp.special = {
  [7] = 'a',
  [8] = 'b',
  [9] = 't',
  [10] = 'n',
  [11] = 'v',
  [12] = 'f',
  [13] = 'r'
}
pp.loadColors = function()
  quote = pp.colorize('quotes', "'", 'string')
  quote2 = pp.colorize('quotes', "'")
  dquote = pp.colorize('quotes', '"', 'string')
  dquote2 = pp.colorize('quotes', '"')
  obrace = pp.colorize('braces', '{ ')
  cbrace = pp.colorize('braces', '}')
  obracket = pp.colorize('property', '[')
  cbracket = pp.colorize('property', ']')
  comma = pp.colorize('sep', ', ')
  equals = pp.colorize('sep', ' = ')
  controls = { }
  for i = 0, 31 do
    local c = pp.special[i]
    if not c then
      if i < 10 then
        c = "00" .. tostring(i)
      else
        c = "0" .. tostring(i)
      end
    end
    controls[i] = pp.colorize('escape', '\\' .. c, 'string')
  end
  controls[92] = pp.colorize('escape', '\\\\', 'string')
  controls[34] = pp.colorize('escape', '\\"', 'string')
  controls[39] = pp.colorize('escape', "\\'", 'string')
  for i = 128, 255 do
    local c
    if i < 100 then
      c = "0" .. tostring(i)
    else
      c = tostring(i)
    end
    controls[i] = pp.colorize('escape', '\\' .. c, 'string')
  end
end
pp.dump = function(value, recurse, nocolor)
  local seen, output, offset, stack
  seen = { }
  output = { }
  offset = 0
  stack = { }
  local recalcOffset
  recalcOffset = function(index)
    for i = index + 1, #output do
      local m = string.match(output[i], "\n([^\n]*)$")
      if m then
        offset = #(STRIP(m))
      else
        offset = offset + #(STRIP(output[i]))
      end
    end
  end
  local write
  write = function(text, length)
    if not length then
      length = #(STRIP(text))
    end
    local i
    i = 1
    while offset + length > log.width and stack[i] do
      local entry
      entry = stack[i]
      if not entry.opened then
        entry.opened = true
        table.insert(output, entry.index + 1, "\n" .. string.rep("  ", i))
        recalcOffset(entry.index)
        for j = i + 1, #stack do
          stack[j].index = stack[j].index + 1
        end
      end
      i = i + 1
    end
    output[#output + 1] = text
    offset = offset + length
    if offset > log.width then
      return pp.dump(stack)
    end
  end
  local indent
  indent = function()
    stack[#stack + 1] = {
      index = #output,
      opened = false
    }
  end
  local unindent
  unindent = function()
    stack[#stack] = nil
  end
  local process
  process = function(localValue)
    local typ = type(localValue)
    if typ == 'string' then
      if string.match(localValue, "'") and not string.match(localValue, '"') then
        return write(dquote .. string.gsub(localValue, '[%c\\\128-\255]', stringEscape) .. dquote2)
      else
        return write(quote .. string.gsub(localValue, "[%c\\'\128-\255]", stringEscape) .. quote2)
      end
    elseif typ == 'table' and not seen[localValue] then
      if not recurse then
        seen[localValue] = true
      end
      write(obrace)
      local i, total
      i = 1
      total = 0
      for _ in pairs(localValue) do
        total = total + 1
      end
      local nextIndex = 1
      for k, v in pairs(localValue) do
        indent()
        if k == nextIndex then
          nextIndex = k + 1
          process(v)
        else
          if type(k) == "string" and string.find(k, "^[%a_][%a%d_]*$") then
            write(pp.colorize("property", k) .. equals)
          else
            write(obracket)
            process(k)
            write(cbracket .. equals)
          end
          if type(v) == "table" then
            process(v)
          else
            indent()
            process(v)
            unindent()
          end
        end
        if i < total then
          write(comma)
        else
          write(" ")
        end
        i = i + 1
        unindent()
      end
      return write(cbrace)
    else
      return write(pp.colorize(typ, tostring(localValue)))
    end
  end
  process(value)
  local s = table.concat(output, "")
  return nocolor and STRIP(s) or s
end
pp.prettyPrint = function(...)
  local n = select('#', ...)
  local arguments = {
    ...
  }
  for i = 1, n do
    arguments[i] = pp.dump(arguments[i])
  end
  return log.print(table.concat(arguments, "\t"))
end
setmetatable(pp, {
  __call = function(table, ...)
    return pp.prettyPrint(...)
  end
})
pp.loadColors()
dumpAST = function(value)
  local seen, output, offset, stack
  seen = { }
  output = { }
  offset = 0
  stack = { }
  local recalcOffset
  recalcOffset = function(index)
    for i = index + 1, #output do
      local m = string.match(output[i], "\n([^\n]*)$")
      if m then
        offset = #(STRIP(m))
      else
        offset = offset + #(STRIP(output[i]))
      end
    end
  end
  local write
  write = function(text, length)
    if not length then
      length = #(STRIP(text))
    end
    local i
    i = 1
    while offset + length > log.width and stack[i] do
      local entry
      entry = stack[i]
      if not entry.opened then
        entry.opened = true
        table.insert(output, entry.index + 1, "\n" .. string.rep("  ", i))
        recalcOffset(entry.index)
        for j = i + 1, #stack do
          stack[j].index = stack[j].index + 1
        end
      end
      i = i + 1
    end
    output[#output + 1] = text
    offset = offset + length
    if offset > log.width then
      return pp.dump(stack)
    end
  end
  local indent
  indent = function()
    stack[#stack + 1] = {
      index = #output,
      opened = false
    }
  end
  local unindent
  unindent = function()
    stack[#stack] = nil
  end
  local process
  process = function(localValue)
    local typ = type(localValue)
    if typ == 'string' then
      if string.match(localValue, "'") and not string.match(localValue, '"') then
        return write(dquote .. string.gsub(localValue, '[%c\\\128-\255]', stringEscape) .. dquote2)
      else
        return write(quote .. string.gsub(localValue, "[%c\\'\128-\255]", stringEscape) .. quote2)
      end
    elseif typ == 'table' then
      local tag
      tag = localValue.tag
      if tag then
        write(log.lightblue .. tag)
      end
      write(obrace)
      local i, total
      i = 1
      total = 0
      for _ in ipairs(localValue) do
        total = total + 1
      end
      local nextIndex = 1
      for k, v in ipairs(localValue) do
        indent()
        if k == nextIndex then
          nextIndex = k + 1
          process(v)
        else
          if type(k) == "string" and string.find(k, "^[%a_][%a%d_]*$") then
            write(pp.colorize("property", k) .. equals)
          else
            write(obracket)
            process(k)
            write(cbracket .. equals)
          end
          if type(v) == "table" then
            process(v)
          else
            indent()
            process(v)
            unindent()
          end
        end
        if i < total then
          write(comma)
        else
          write(" ")
        end
        i = i + 1
        unindent()
      end
      return write(cbrace)
    else
      return write(pp.colorize(typ, tostring(localValue)))
    end
  end
  process(value)
  local s = table.concat(output, "")
  return nocolor and STRIP(s) or s
end
log._ = _
log.log = log
log.inspect = inspect
log.detail = function(o, depth)
  if depth == nil then
    depth = 2
  end
  return log.print(inspect(o, {
    depth = depth
  }))
end
log.ins1 = function(o)
  return inspect(o, {
    depth = 1
  })
end
log.ins2 = function(o)
  return inspect(o, {
    depth = 2
  })
end
log.ins3 = function(o)
  return inspect(o, {
    depth = 3
  })
end
log.bit = bit
log.hex = hex
log.pp = pp
log.theme = theme
log.colorize = pp.colorize
log.dump = pp.dump
log.dumpAST = dumpAST
log.printAST = function(ast, ...)
  return log.print(dumpAST(ast, ...))
end
center = function(str, width, char)
  local strwidth = string.len(str)
  local fillwidth = width - strwidth
  local left = string.rep(char, math.floor(fillwidth / 2))
  local right = string.rep(char, math.ceil(fillwidth / 2))
  return left .. str .. right
end
log.title = function(msg, c)
  if not (log.useColors) then
    log.print(center("[ " .. tostring(msg) .. " ]", log.width, '='))
    return 
  end
  c = c or theme.comment
  local _msg = STRIP(msg)
  local str = c .. center("[ " .. tostring(_msg) .. " ]", log.width, '=')
  if #msg ~= #_msg then
    str = string.gsub(str, _msg, (msg .. c))
  end
  return log.print(str)
end
log.subtitle = function(msg, c)
  local len = string.len(STRIP(msg))
  c = c or CSI('38;5;242')
  c = log.useColors and c or ''
  local fill = string.rep('-', log.width - len)
  return log.print(msg .. c .. fill)
end
log.comment = function(s)
  return pp.colorize('comment', s)
end
return log
