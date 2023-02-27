load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

load("@rules_ocaml//ocaml:providers.bzl",
     "OcamlNsMarker",
     "OcamlProvider",
     "OcamlArchiveMarker",
     "OcamlImportMarker",
     "OcamlLibraryMarker",
     )

load("@rules_ocaml//ppx:providers.bzl",
     "PpxCodepsProvider",
     # "PpxModuleMarker",
)

load(":BUILD.bzl", "JsooInfo", "jsoo_transition")

def _transpile_src(ctx, tc, src):
    outfile = ctx.actions.declare_file(src.basename + ".js")

    args = ctx.actions.args()
    args.add_all(ctx.attr.opts)
    args.add("-o")
    args.add(outfile.path)
    args.add(src.path)

    ctx.actions.run(
        inputs  = [src],
        outputs = [outfile],
        executable = tc.compiler,
        arguments  = [args],
        # env  = ctx.attr.env,
                tools = [tc.compiler],
        mnemonic = "JSOOLibrary",
        progress_message = "compiling jsoo lib: {lib}".format(
            lib = src.basename
        )
    )
    return outfile

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

    codep_archives = []
    jsoo_runtimes = []
    for src in ctx.attr.srcs: # cmos:
        if PpxCodepsProvider in src:
            codep_archives.append(src[PpxCodepsProvider].archives)
            if hasattr(src[PpxCodepsProvider], "jsoo_runtimes"):
                jsoo_runtimes.append(src[PpxCodepsProvider].jsoo_runtimes)
                print("codep runtimes: %s" % src[PpxCodepsProvider].jsoo_runtimes)
        if OcamlProvider in src:
            if hasattr(src[OcamlProvider], "jsoo_runtimes"):
                jsoo_runtimes.append(src[OcamlProvider].jsoo_runtimes)
                print("dep runtimes: %s" % src[OcamlProvider].jsoo_runtimes)

    print("jsoo ppx_codep archives: %s" % codep_archives)
    print("jsoo_runtimes: %s" % jsoo_runtimes)

    ## merge codeps
    codeps_depset = depset(transitive = codep_archives)
    for archive in codeps_depset.to_list():
        if archive.extension == "cma":
            print(" archive: %s" % archive)
            outputs.append(
                _transpile_src(ctx, tc, archive)
            )

    ## jsoo compiler can only transpile one file at a time?
    for src in ctx.files.srcs: # cmos:
        if src.extension in ["cmo", "cma"]:
            outputs.append(
                _transpile_src(ctx, tc, src)
            )

    if ctx.attr.deps:
        indirects = []
        for d in ctx.attr.deps:
            indirects.append(d[JsInfo].sources)
    else:
        indirects = []

    js_info_depset =depset(
            direct = outputs,
            # transitive = indirects
    )

    jsooInfo = JsooInfo(
        runtimes = jsoo_runtimes,
    )
    print("jsooInfo: %s" % jsooInfo)

    outputGroupInfo = OutputGroupInfo(
        all = js_info_depset
    )

    return [
        DefaultInfo(files=depset(direct = outputs)),
        js_info(sources = js_info_depset),
        jsooInfo,
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
