
### require 'log'

Personnal logging utility. Provided AS-IS, MIT.

- `log.pp` pretty-printer, based on luvit's pp
- `log.hex` pretty-print hex content (either string or io.open's file)
- `log.bit` pretty-print bit number

```moonscript

log.title 'Hey'
-- ======================[ Hey ]============================= |<- terminal width

print log.yellow.light 'Hey'     -- yellow Hey
print log.red.white.bg 'Hey'     -- Red on White Hey

```
