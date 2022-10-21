load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load("@rules_ocaml//ocaml:providers.bzl",
     "OcamlNsMarker",
     "OcamlProvider",
     "OcamlArchiveMarker",
     "OcamlImportMarker",
     "OcamlLibraryMarker",
     )

load(":BUILD.bzl", "jsoo_transition")

############################
def _jsoo_library_impl(ctx):

    print("jsoo_library: %s" % ctx.label)

    tc = ctx.toolchains["@rules_jsoo//toolchain/type:std"]

    outputs = []
    cmos = []
    srcs = None

    # attr defn ensures each src will be .cmo or .cma
    # for f in ctx.files.srcs:
    #     cmos.append(s[OcamlProvider].struct)
        # must be from exports_files or a filegroup



    ## jsoo compiler can only transpile one .cmo file at a time
    for cmo in ctx.files.srcs: # cmos:
        if cmo.extension in ["cmo", "cma"]:
            outfile = ctx.actions.declare_file(cmo.basename + ".js")

            args = ctx.actions.args()
            args.add_all(ctx.attr.opts)
            args.add("-o")
            args.add(outfile.path)
            args.add(cmo.path)

            ctx.actions.run(
                inputs  = [cmo],
                outputs = [outfile],
                executable = tc.compiler,
                arguments  = [args],
                # env  = ctx.attr.env,
                tools = [tc.compiler],
                mnemonic = "JSOOLibrary",
                progress_message = "compiling jsoo lib"
            )
            outputs.append(outfile)

    if ctx.attr.deps:
        indirects = []
        for d in ctx.attr.deps:
            indirects.append(d[JsInfo].sources)
    else:
        indirects = []

    js_info_depset =depset(
            direct = outputs,
            transitive = indirects
    )

    outputGroupInfo = OutputGroupInfo(
        all = js_info_depset
    )

    return [
        DefaultInfo(files=depset(direct = outputs)),
        js_info(sources = js_info_depset),
        outputGroupInfo
    ]

####################
jsoo_library = rule(
    implementation = _jsoo_library_impl,
    doc = "Turns bc into js",
    attrs = dict(
        srcs = attr.label_list(
            allow_files = [".cmo", ".cma"], # True, ## ??
            # providers must provide .cmo or .cma
            # providers = [[OcamlProvider],
            #              [OcamlNsMarker],
            #              [OcamlArchiveMarker],
            #              [OcamlLibraryMarker]],
            cfg = jsoo_transition
        ),
        deps = attr.label_list(
            providers = [JsInfo]
            # cfg = jsoo_transition
        ),
        # for cfg attribute above:
        _allowlist_function_transition = attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist"
        ),
        opts = attr.string_list(
            doc = "jsoo compile options"
        ),
        # compiler = attr.label(
        #     mandatory = True,
        #     executable = True,
        #     cfg = "exec"
        # )
    ),
    executable = False,
    provides = [JsInfo],
    toolchains = ["@rules_jsoo//toolchain/type:std"],
)
