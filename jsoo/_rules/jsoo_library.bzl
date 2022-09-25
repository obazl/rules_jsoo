load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load("@rules_ocaml//ocaml:providers.bzl",
     "OcamlNsMarker",
     "OcamlProvider",
     "OcamlArchiveMarker",
     "OcamlImportMarker",
     "OcamlLibraryMarker",
     )

def _jsoo_transition_impl(settings, attr):
    # set target platform to vm force inputs to bytecode
    return {
        "//command_line_option:platforms" : "@ocaml//host/target:vm"
        # "@ocaml//host/target": "@ocaml//host/target:vm?"
    }

_jsoo_transition = transition(
    implementation = _jsoo_transition_impl,
    inputs = [
        # special labels for Bazel native command line args:
        # "//command_line_option:host_platform",
        # "//command_line_option:platforms",
    ],
    outputs = [
        "//command_line_option:platforms",
        # "@rules_ocaml//cfg/toolchain:build-host",
        # "@rules_ocaml//cfg/toolchain:target-host"
    ]
)

############################
def _jsoo_library_impl(ctx):

    print("jsoo_library")

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
            cfg = _jsoo_transition
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
