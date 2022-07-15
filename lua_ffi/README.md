## Test

```
local print = print

local cuckoofilter_ffi = require "cuckoo_filter"

local cuckoofilter = cuckoofilter_ffi:new(1024)

print("add: ", cuckoofilter:add(4))
print("contains: ", cuckoofilter:contains(4))
print("len: ", cuckoofilter:len())
print("memory_usage: ", cuckoofilter:memory_usage())
print("delete: ", cuckoofilter:delete(4))
print("contains: ", cuckoofilter:contains(4))
print("len: ", cuckoofilter:len())
print("memory_usage: ", cuckoofilter:memory_usage())

```

Output 

```
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:23: add: RCF_OK
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:24: contains: RCF_OK
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:25: len: 1
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:26: memory_usage: 1048
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:27: delete: RCF_OK
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:28: contains: RCF_NOT_FOUND
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:29: len: 0
2022/07/15 16:02:19 [notice] 2599#0: [lua] on_init.lua:30: memory_usage: 1048
```
