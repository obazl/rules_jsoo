load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load("@rules_ocaml//ocaml:providers.bzl",
     "OcamlExecutableMarker",
     "OcamlNsMarker",
     "OcamlProvider",
     "OcamlTestMarker",
     )
load("@rules_ocaml//ppx:providers.bzl",
     "PpxCodepsProvider",
)

load(":BUILD.bzl", "JsooInfo", "jsoo_transition")

###########################
def _jsoo_link_binary_impl(ctx):

    ## Tasks: 1.  Compile ctx.file.exe, the cmo executable
    ##        2.  Link with stdlib, std_exit, and deps

    tc = ctx.toolchains["@rules_jsoo//toolchain/type:std"]

    # print("tc: %s" % tc)

    out_main = ctx.actions.declare_file(ctx.label.name)
    ## fixme: add .js if missing?

    # TODO: iterate of ctx.attr.deps extracting runtime.js files,
    # then run jsoo build-runtime

    for dep in ctx.attr.deps:
        if OcamlProvider in dep:
            provider = dep[OcamlProvider]
            print("Dep jsoo_runtime: %s" % provider.jsoo_runtimes)
            if provider.jsoo_runtime:
                    fail("dddddddddddddddd")
        if PpxCodepsProvider in dep:
            provider = dep[PpxCodepsProvider]
            print("Dep jsoo_runtime: %s" % provider.jsoo_runtimes)
            if provider.jsoo_runtime:
                    fail("mmmmmmmmmmmmmmmm")
        if JsooInfo in dep:
            provider = dep[JsooInfo]
            print("Dep jsoo_runtimes: %s" % provider.runtimes)

    if ctx.attr.runtime:
        runtime = ctx.file.runtime
    else:
        runtime = tc.runtime

    ################################################################
    args = ctx.actions.args()
    args.add("link")
    args.add(runtime.path)
    args.add(tc.stdlib.path)
    args.add_all(ctx.files.deps)
    args.add(ctx.file.main.path)
    args.add(tc.std_exit.path)

    args.add("-o")
    args.add(out_main.path)

    action_inputs = [
        # out_main,
        ctx.file.main,
        runtime,
        tc.stdlib,
        tc.std_exit,
    ] +  ctx.files.deps

    ctx.actions.run(
        inputs  = action_inputs, # [ctx.file.main] + ctx.files.deps,
        outputs = [out_main],
        executable = tc.compiler,
        arguments  = [args],
        # env  = ctx.attr.env,
        tools = [tc.compiler],
        mnemonic = "JSOOLinkExecutable",
        progress_message = "JSOO linking executable: {ws}//{pkg}:{tgt}".format(
            ws  = "@" + ctx.label.workspace_name if ctx.label.workspace_name else "", ## ctx.workspace_name,
            pkg = ctx.label.package,
            tgt=ctx.label.name,
        )
    )

    # # Step 2: link
    # out_exe = ctx.actions.declare_file(ctx.file.main.basename + ".out.js")
    # args = ctx.actions.args()
    # args.add("link")
    # args.add_all(ctx.attr.opts)
    # args.add("-o")
    # args.add(out_exe.path)
    # args.add(tc.runtime.path)
    # args.add(tc.stdlib.path)
    # args.add(out_main)
    # args.add(tc.std_exit.path)

    # # print("MAIN: %s" % out_main)

    # action_inputs = [
    #     out_main,
    #     tc.runtime,
    #     tc.stdlib,
    #     tc.std_exit,
    # ]

    # ctx.actions.run(
    #     inputs  = action_inputs,
    #     outputs = [out_exe],
    #     executable = tc.compiler,
    #     arguments  = [args],
    #     # env  = ctx.attr.env,
    #     tools = [tc.compiler],
    #     mnemonic = "JSOOLink",
    #     progress_message = "JSOO compilation of bc executable file."
    # )

    return [
        DefaultInfo(files=depset(direct = [out_main])),
        js_info(
            sources = depset(direct = [out_main]),
            # transitive_sources = depset(
            #     direct = [
            #         tc.runtime,
            #         tc.stdlib,
            #         tc.std_exit,
            #     ])
        )
    ]

####################
jsoo_link_binary = rule(
    implementation = _jsoo_link_binary_impl,
    doc = "Link js files into executable.",
    attrs = dict(
        main = attr.label(
            allow_single_file = True, ## ??
            providers = [JsInfo],
            # cfg = jsoo_transition
        ),
        runtime = attr.label(
            allow_single_file = True,
            providers = [JsInfo],
            # cfg = jsoo_transition
        ),
        deps = attr.label_list(
            # allow_single_file = True, ## ??
            providers = [JsInfo],
            # cfg = jsoo_transition
        ),
        opts = attr.string_list(
            doc = "jsoo link options"
        ),
        # for user-defined cfg attribute:
        # _allowlist_function_transition = attr.label(
        #     default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        # ),
    ),
    executable = False,
    provides = [JsInfo],
    toolchains = ["@rules_jsoo//toolchain/type:std"],
)
