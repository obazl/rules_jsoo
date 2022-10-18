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
def _jsoo_module_impl(ctx):

    print("jsoo_module")

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
        if cmo.extension == "cmo":
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
                mnemonic = "JSOOCompile",
                progress_message = "JSOO compilation"
            )
            outputs.append(outfile)

    return [
        DefaultInfo(files=depset(direct = outputs)),
        js_info(
            sources = depset(direct = outputs)
        )
    ]

####################
jsoo_module = rule(
    implementation = _jsoo_module_impl,
    doc = "Turns bc into js",
    attrs = dict(
        src = attr.label(
            allow_single_file = True,
            providers = [[OcamlProvider]],
            cfg = jsoo_transition
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
