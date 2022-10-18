load(":BUILD.bzl", "jsoo_transition")

############################
def _build_runtime(ctx, tc):
    args = ctx.actions.args()
    args.add("build-runtime")
    args.add_all(ctx.files.srcs)
    # for f in ctx.files.srcs:
    #     args.add(f.path)
    args.add_all(ctx.attr.opts)
    args.add("-o")
    args.add_all(ctx.outputs.outs)

    ctx.actions.run(
        inputs  = ctx.files.srcs,
        executable = tc.compiler,
        arguments  = [args],
        outputs = ctx.outputs.outs,
        tools = [tc.compiler],
        mnemonic = "JSOOBuildRuntime",
        progress_message = "JSOO build runtime"
    )

    return [
        DefaultInfo(files=depset(direct = ctx.outputs.outs)),
    ]

############################
def _check_runtime(ctx, tc):

    if len(ctx.outputs.outs) > 1:
        fail("only one output allowed for cmd 'check'")

    args = ctx.actions.args()
    args.add("check-runtime")
    args.add_all(ctx.files.srcs)
    args.add_all(ctx.attr.opts)

    ctx.actions.run_shell(
        inputs  = ctx.files.srcs,
        outputs = ctx.outputs.outs,
        command = " ".join([
            tc.compiler.path,
            "$@",
            "> %s" % ctx.outputs.outs[0].path
        ]),
        arguments  = [args],
        tools = [tc.compiler],
        mnemonic = "JSOOCheckRuntime",
        progress_message = "JSOO check runtime"
    )

    return [
        DefaultInfo(files=depset(direct = ctx.outputs.outs)),
        # js_info(
        #     sources = depset(direct = [out_exe]),
        #     transitive_sources = depset(
        #         direct = [
        #             tc.runtime,
        #             tc.stdlib,
        #             tc.std_exit,
        #         ])
        # )
    ]

############################
def _print_runtime(ctx, tc):
    if len(ctx.attr.srcs) > 0:
        fail("srcs must be empty for jsoo_runtime action 'print'")
    args = ctx.actions.args()
    args.add("print-standard-runtime")
    ctx.actions.run_shell(
        outputs = ctx.outputs.outs,
        command = " ".join([
            tc.compiler.path,
            "$@",
            "> %s" % ctx.outputs.outs[0].path
        ]),
        arguments  = [args],
        tools = [tc.compiler],
        mnemonic = "JSOOPrintRuntime",
        progress_message = "JSOO print runtime"
    )

    return [
        DefaultInfo(files=depset(direct = ctx.outputs.outs)),
    ]

###########################
def _jsoo_runtime_impl(ctx):

    tc = ctx.toolchains["@rules_jsoo//toolchain/type:std"]

    print("tc: %s" % tc)

    if ctx.attr.action == "build":
        return _build_runtime(ctx, tc)
    elif ctx.attr.action == "build-fs":
        action = "build-fs"
        print(action)
    elif ctx.attr.action == "check":
        return _check_runtime(ctx, tc)
    elif ctx.attr.action == "print":
        return _print_runtime(ctx, tc)
    else:
        print(ctx.attr.action)
        fail("xxxxxxxxxxxxxxxx")

####################
jsoo_runtime = rule(
    implementation = _jsoo_runtime_impl,
    doc = "Execute js_of_ocaml build-runtime or check-runtime.",
    attrs = dict(
        action = attr.string(
            mandatory = True,
            values = ["build", "check", "print", "build-fs"]
        ),
        # action = attr.string(
        #     mandatory = True,
        #     values = ["build", "check"]
        # ),
        srcs = attr.label_list(
            allow_files = True, ## ??
            # providers = [OcamlExecutableMarker],
            # inputs: js for build-runtime, bc for check-runtime?
            cfg = jsoo_transition
        ),
        outs = attr.output_list(
            mandatory = True,
            allow_empty = False
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
    # provides = [JsInfo],
    toolchains = ["@rules_jsoo//toolchain/type:std"],
)
