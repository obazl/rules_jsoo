load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load("@rules_ocaml//ocaml:providers.bzl",
     "OcamlExecutableMarker",
     "OcamlNsMarker",
     "OcamlProvider",
     "OcamlTestMarker",
     )

load(":BUILD.bzl", "jsoo_transition")

###########################
def _jsoo_binary_impl(ctx):

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
        progress_message = "JSOO compilation of bc executable file."
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
jsoo_binary = rule(
    implementation = _jsoo_binary_impl,
    doc = "Compile .cmo and link with JsInfo deps into executable.",
    attrs = dict(
        main = attr.label(
            allow_single_file = True, ## ??
            providers = [
                [OcamlExecutableMarker],
                # [OcamlProvider],
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
    executable = False,
    provides = [JsInfo],
    toolchains = ["@rules_jsoo//toolchain/type:std"],
)
