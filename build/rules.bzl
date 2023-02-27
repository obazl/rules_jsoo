"""Public definitions for JSOO rules.

All public rules imported and re-exported in this file.

Definitions outside this file are private unless otherwise noted, and
may change without notice.
"""

load("//jsoo/_rules:jsoo_binary.bzl",  _jsoo_binary  = "jsoo_binary")
load("//jsoo/_rules:jsoo_link_binary.bzl",  _jsoo_link_binary  = "jsoo_link_binary")
# load("//jsoo/_rules:jsoo_module.bzl",  _jsoo_module  = "jsoo_module")
load("//jsoo/_rules:jsoo_import.bzl", _jsoo_import = "jsoo_import")
load("//jsoo/_rules:jsoo_library.bzl", _jsoo_library = "jsoo_library")
load("//jsoo/_rules:jsoo_runtime.bzl", _jsoo_runtime = "jsoo_runtime")
load("//jsoo/_rules:jsoo_test.bzl", _jsoo_test_binary = "jsoo_test_binary")

jsoo_binary  = _jsoo_binary
jsoo_link_binary  = _jsoo_link_binary
# jsoo_module  = _jsoo_module
jsoo_import = _jsoo_import
jsoo_library = _jsoo_library
jsoo_runtime = _jsoo_runtime
jsoo_test_binary = _jsoo_test_binary
