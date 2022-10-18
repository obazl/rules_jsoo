# ocaml_test: links an executable using the ocaml toolchain, then runs it

# ideally jsoo_test would "link" a js executable using the jsoo
# toolchain, but that would require the we implement a js runner,
# which would be complicated. Other rulesets (rules_js, rules_swc,
# etc.) already do this.

# but we do need to test the jsoo compiler itself. and we need to be
# able to run its several subcommands. genrule would suffice to run
# jsoo, but we also need a transition on the deps, to switch to a >vm
# toolchain. so we need a custom rule.

# name? jsoo_test isn't appropriate, it is not a test run. rather it
# is intended to run jsoo.

# jsoo_run_binary, following js_run_binary?

# jsoo_runner?  jsoo_genrule?

# why not just use jsoo_binary? Because its intended use is to produce
# js files. We need a different rule to run jsoo for different
# purposes. I.e. jsoo subcommands: build-fs, build-runtime,
# check-runtime, print-standard-runtime.

# what those subcommands have in common is runtime.  so jsoo_runtime?

# jsoo_test is for running the jsoo compiler, with bytecode inputs
# i.e. it is for testing jsoo and running its subcommands.

# use js_test to run js tests

