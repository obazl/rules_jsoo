"""Public definitions for JSOO rules.

All public rules imported and re-exported in this file.

Definitions outside this file are private unless otherwise noted, and
may change without notice.
"""

load("//jsoo/_rules:jsoo_binary.bzl", _jsoo_binary = "jsoo_binary")
load("//jsoo/_rules:jsoo_library.bzl", _jsoo_library = "jsoo_library")

jsoo_binary = _jsoo_binary
jsoo_library = _jsoo_library
