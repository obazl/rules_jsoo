# ocaml_test_binary: links an executable using the ocaml toolchain, then runs it

# ideally jsoo_test_binary would "link" a js executable using the jsoo
# toolchain, but that would require the we implement a js runner,
# which would be complicated. Other rulesets (rules_js, rules_swc,
# etc.) already do this.

# but we do need to test the jsoo compiler itself. and we need to be
# able to run its several subcommands. genrule would suffice to run
# jsoo, but we also need a transition on the deps, to switch to a >vm
# toolchain. so we need a custom rule.

# name? jsoo_test_binary isn't appropriate, it is not a test run. rather it
# is intended to run jsoo.

# jsoo_run_binary, following js_run_binary?

# jsoo_runner?  jsoo_genrule?

# why not just use jsoo_binary? Because its intended use is to produce
# js files. We need a different rule to run jsoo for different
# purposes. I.e. jsoo subcommands: build-fs, build-runtime,
# check-runtime, print-standard-runtime.

# what those subcommands have in common is runtime.  so jsoo_runtime?

# jsoo_test_binary is for running the jsoo compiler, with bytecode inputs
# i.e. it is for testing jsoo and running its subcommands.

# use js_test_binary to run js tests

load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load("@rules_ocaml//ocaml:providers.bzl",
     "OcamlExecutableMarker",
     "OcamlNsMarker",
     "OcamlProvider",
     "OcamlTestMarker",
     )

load(":BUILD.bzl", "jsoo_transition")

###########################
def _jsoo_test_binary_impl(ctx):

    ## Tasks: 1.  Compile ctx.file.exe, the cmo executable
    ##        2.  Link with stdlib, std_exit, and deps

    tc = ctx.toolchains["@rules_jsoo//toolchain/type:std"]

    # print("tc: %s" % tc)

    # Step 1: compile bc executabel to js
    out_main = ctx.actions.declare_file(ctx.file.main.basename + ".js")
    args = ctx.actions.args()
    args.add("compile")
    args.add_all(ctx.attr.opts)
    args.add("-o")
    args.add(out_main.path)
    args.add(ctx.file.main.path)

    ctx.actions.run(
        inputs  = [ctx.file.main],
        outputs = [out_main],
        executable = tc.compiler,
        arguments  = [args],
        # env  = ctx.attr.env,
        tools = [tc.compiler],
        mnemonic = "JSOOCompileMain",
        progress_message = "JSOO compiling main: {ws}//{pkg}:{tgt}".format(
            ws  = "@" + ctx.label.workspace_name if ctx.label.workspace_name else "", ## ctx.workspace_name,
            pkg = ctx.label.package,
            tgt=ctx.label.name,
        )
    )

    # Step 2: link
    out_exe = ctx.actions.declare_file(ctx.file.main.basename + ".out.js")
    args = ctx.actions.args()
    args.add("link")
    args.add_all(ctx.attr.opts)
    args.add("-o")
    args.add(out_exe.path)
    args.add(tc.runtime.path)
    args.add(tc.stdlib.path)
    args.add(out_main)
    args.add(tc.std_exit.path)

    # print("MAIN: %s" % out_main)

    action_inputs = [
        out_main,
        tc.runtime,
        tc.stdlib,
        tc.std_exit,
    ]

    ctx.actions.run(
        inputs  = action_inputs,
        outputs = [out_exe],
        executable = tc.compiler,
        arguments  = [args],
        # env  = ctx.attr.env,
        tools = [tc.compiler],
        mnemonic = "JSOOLink",
        progress_message = "JSOO test compilation of bc executable file."
    )

    return [
        DefaultInfo(files=depset(direct = [out_exe])),
        js_info(
            sources = depset(direct = [out_exe]),
            transitive_sources = depset(
                direct = [
                    tc.runtime,
                    tc.stdlib,
                    tc.std_exit,
                ])
        )
    ]

####################
jsoo_test_binary = rule(
    implementation = _jsoo_test_binary_impl,
    doc = "Compile .cmo and link with JsInfo deps into executable.",
    attrs = dict(
        main = attr.label(
            allow_single_file = True, ## ??
            providers = [
                [OcamlExecutableMarker],
                [OcamlTestMarker]
            ],
            cfg = jsoo_transition
        ),
        opts = attr.string_list(
            doc = "jsoo link options"
        ),
        # for user-defined cfg attribute:
        _allowlist_function_transition = attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        ),
    ),
    # test = True,
    # executable = False,
    provides = [JsInfo],
    toolchains = ["@rules_jsoo//toolchain/type:std"],
)
