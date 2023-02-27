load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load(":BUILD.bzl", "jsoo_transition")

# to build a runtime we get the jsoo_runtimes from deps, then pass
# them as cli args to the jsoo tool. problem is the paths are relative
# to the bazel execroot (e.g. /private/var/.../execroot/js_of_ocaml_dev),
# which the jsoo tool treats as relative to _its_ location.

# that is, bazel runs the tool indirectly, by changing dir to the
# execroot, then running `exec env` with the tool path as an
# argument. E.g. 'exec env
# bazel-out/darwin-opt-exec-2B5CBBC6/bin/compiler/bin-js_of_ocaml/js_of_ocaml.exe'.
# So the tool cannot find the files pass as args relative to the
# execroot, like 'external/opam_base/lib/base/runtime.js'.

# verify this by removing the tooldir prefix, e.g.
#     args.add("../../../../../" + src.path)
# effectively "backing up" to make the path relative to the tooldir.

# here src.path is the std bazel path, relative to the execroot,
# e.g. external/opam_base/lib/base/runtime.js

# to deal with this, we have two options. one is to modify the paths
# as above. the other is to use the runfiles feature of bazel.

# option 2: we need to add the args to the runfiles of the
# tool, so they will automatically be accessible relative to the
# toolroot rather than the bazel execroot.

# we cannot modify the runfiles dir of the tool we're depending on, so
# instead we need to wrap it in a shell script whose runfiles we
# control.

# so for option 2 our tasks would be:
# * emit an executable (script) whose runfiles contain our runtime.js deps
# * run that script to produce the merged runtime.js

############################
def _build_runtime(ctx, tc):

    srcs = []
    runfiles = []
    ftrs = []

    # 1. Arg paths are relative to execroot; we need to make them
    # relative to the tooldir. We do this by constructing a prefix of
    # '../' segs, so when they are passed to the jsoo tool it will
    # "back up" to find them relative to the execroot.
    segs = tc.compiler.dirname.split("/")
    pfx = ""
    for i in range(len(segs)):
        pfx = pfx + "../"

    for src in ctx.attr.srcs:
        runfiles.extend(src[DefaultInfo].default_runfiles.files.to_list())

        for f in src[DefaultInfo].files.to_list():
            srcs.append(pfx + f.path)

        # srcs.extend(f[DefaultInfo].files.to_list())

        # ftrs.append(f[DefaultInfo].files_to_run)
        # print("FTRS: %s" % ftrs)
        # for ftr in ftrs:
        #     print("FTR manifest: %s" % ftr.runfiles_manifest)


    args = ctx.actions.args()
    args.add("build-runtime")

    for src in srcs:
        args.add(src)

    # args.add(tc.runtime)

    args.add_all(ctx.attr.opts)

    args.add("-o")
    args.add_all(ctx.outputs.outs)

    ctx.actions.run(
        inputs  = runfiles, # ctx.files.srcs,
        executable = tc.compiler,
        arguments  = [args],
        outputs = ctx.outputs.outs,
        tools = [tc.compiler],
        mnemonic = "JSOOBuildRuntime",
        progress_message = "JSOO build runtime"
    )

    return [
        DefaultInfo(files=depset(direct = ctx.outputs.outs)),
        js_info(
            sources = depset(direct = ctx.outputs.outs)
        )
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
