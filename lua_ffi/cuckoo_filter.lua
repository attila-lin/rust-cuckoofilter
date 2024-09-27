local ffi = require "ffi"
local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local setmetatable = setmetatable
local tonumber = tonumber

local _M = {}

local cuckoofilter = ffi_load("libcuckoofilter_cabi.so")

ffi_cdef [[

typedef enum rcf_cuckoofilter_status {
  RCF_OK,
  RCF_NOT_FOUND,
  RCF_NOT_ENOUGH_SPACE,
} rcf_cuckoofilter_status;

/**
 * A cuckoo filter class exposes a Bloomier filter interface,
 * providing methods of add, delete, contains.
 *
 * # Examples
 *
 * ```
 * extern crate cuckoofilter;
 *
 * let words = vec!["foo", "bar", "xylophone", "milagro"];
 * let mut cf = cuckoofilter::CuckooFilter::new();
 *
 * let mut insertions = 0;
 * for s in &words {
 *     if cf.test_and_add(s).unwrap() {
 *         insertions += 1;
 *     }
 * }
 *
 * assert_eq!(insertions, words.len());
 * assert_eq!(cf.len(), words.len());
 *
 * // Re-add the first element.
 * cf.add(words[0]);
 *
 * assert_eq!(cf.len(), words.len() + 1);
 *
 * for s in &words {
 *     cf.delete(s);
 * }
 *
 * assert_eq!(cf.len(), 1);
 * assert!(!cf.is_empty());
 *
 * cf.delete(words[0]);
 *
 * assert_eq!(cf.len(), 0);
 * assert!(cf.is_empty());
 *
 * for s in &words {
 *     if cf.test_and_add(s).unwrap() {
 *         insertions += 1;
 *     }
 * }
 *
 * cf.clear();
 *
 * assert!(cf.is_empty());
 *
 * ```
 */
typedef struct CuckooFilter_DefaultHasher CuckooFilter_DefaultHasher;

/**
 * Opaque type for a cuckoo filter using Rust's `std::collections::hash_map::DefaultHasher` as
 * Hasher. The C ABI only supports that specific Hasher, currently.
 */
typedef struct CuckooFilter_DefaultHasher rcf_cuckoofilter;

/**
 * Constructs a cuckoo filter with a given max capacity.
 * The various wrapper methods of this crate operate on the returned reference.
 * At the end of its life, use [`rcf_cuckoofilter_free`] to free the allocated memory.
 *
 * [`rcf_cuckoofilter_free`]: fn.rcf_cuckoofilter_free.html
 */
rcf_cuckoofilter *rcf_cuckoofilter_with_capacity(uintptr_t capacity);

/**
 * Free the given `filter`, releasing its allocated memory.
 */
void rcf_cuckoofilter_free(rcf_cuckoofilter *filter);

/**
 * Checks if the given `data` is in the `filter`.
 *
 * Returns `rcf_cuckoofilter_status::RCF_OK` if the given `data` is in the `filter`,
 * `rcf_cuckoofilter_status::RCF_NOT_FOUND` otherwise.
 * Aborts if the given `filter` is a null pointer.
 */
enum rcf_cuckoofilter_status rcf_cuckoofilter_contains(const rcf_cuckoofilter *filter,
                                                       uint64_t data);

/**
 * Adds `data` to the `filter`.
 *
 * Returns `rcf_cuckoofilter_status::RCF_OK` if the given `data` was successfully added to the
 * `filter`, `rcf_cuckoofilter_status::RCF_NOT_ENOUGH_SPACE` if the filter could not find a free
 * space for it.
 * Aborts if the given `filter` is a null pointer.
 */
enum rcf_cuckoofilter_status rcf_cuckoofilter_add(rcf_cuckoofilter *filter, uint64_t data);

/**
 * Returns the number of items in the `filter`.
 * Aborts if the given `filter` is a null pointer.
 */
uintptr_t rcf_cuckoofilter_len(const rcf_cuckoofilter *filter);

/**
 * Checks if `filter` is empty.
 * This is equivalent to `rcf_cuckoofilter_len(filter) == 0`
 * Aborts if the given `filter` is a null pointer.
 */
bool rcf_cuckoofilter_is_empty(const rcf_cuckoofilter *filter);

/**
 * Returns the number of bytes the `filter` occupies in memory.
 * Aborts if the given `filter` is a null pointer.
 */
uintptr_t rcf_cuckoofilter_memory_usage(const rcf_cuckoofilter *filter);

/**
 * Deletes `data` from the `filter`.
 * Returns `rcf_cuckoofilter_status::RCF_OK` if `data` existed in the filter before,
 * `rcf_cuckoofilter_status::RCF_NOT_FOUND` if `data` did not exist.
 * Aborts if the given `filter` is a null pointer.
 */
enum rcf_cuckoofilter_status rcf_cuckoofilter_delete(rcf_cuckoofilter *filter, uint64_t data);

]]

local mt = {
    __index = _M
}

local status_map = {
    [ffi.C.RCF_OK] = "RCF_OK",
    [ffi.C.RCF_NOT_FOUND] = "RCF_NOT_FOUND",
    [ffi.C.RCF_NOT_ENOUGH_SPACE] = "RCF_NOT_ENOUGH_SPACE",
}

local function enum_to_string(status)
    local str = status_map[tonumber(status)]
    return str
end

function _M:new(capacity)
    local rcf_cuckoofilter = cuckoofilter.rcf_cuckoofilter_with_capacity(capacity)

    local self = {
        filter = rcf_cuckoofilter,
        status_map = {
            [ffi.C.RCF_OK] = "RCF_OK",
            [ffi.C.RCF_NOT_FOUND] = "RCF_NOT_FOUND",
            [ffi.C.RCF_NOT_ENOUGH_SPACE] = "RCF_NOT_ENOUGH_SPACE",
        },
    }

    return setmetatable(self, mt)
end

function _M:add(data)
    local status = cuckoofilter.rcf_cuckoofilter_add(self.filter, data)
    return enum_to_string(status)
end

function _M:contains(data)
    local status = cuckoofilter.rcf_cuckoofilter_contains(self.filter, data)
    return enum_to_string(status)
end

function _M:delete(data)
    local status = cuckoofilter.rcf_cuckoofilter_delete(self.filter, data)
    return enum_to_string(status)
end

function _M:is_empty()
    return cuckoofilter.rcf_cuckoofilter_is_empty(self.filter)
end

function _M:len()
    local len = cuckoofilter.rcf_cuckoofilter_len(self.filter)
    return tonumber(len)
end

function _M:memory_usage()
    local memory_usage = cuckoofilter.rcf_cuckoofilter_memory_usage(self.filter)
    return tonumber(memory_usage)
end

function _M:free()
    cuckoofilter.rcf_cuckoofilter_free(self.filter)
end

return _M
