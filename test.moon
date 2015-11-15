

i = require 'inspect'

log = require 'log'

p = print
pi = (v) -> print i v
pp = log.pp


print 'Start'

red = log.red
p red 'red'

bg = red.bg
p bg 'bg'

bold = bg.bold
p bold 'bold'

p bg.xcolor(202) 'bg'

p log.xcolor(196).bg.black 'yo 196'

p log.pink.xcolor(241).bg 'pink'

print 'End'
