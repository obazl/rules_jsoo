load("@aspect_rules_js//js:providers.bzl", "js_info", "JsInfo")

############################
def _jsoo_import_impl(ctx):

    print("jsoo_import")

    tc = ctx.toolchains["@rules_jsoo//toolchain/type:std"]

    runfiles = ctx.runfiles(files = [ctx.file.src])

    js_info_depset =depset(
            direct = [ctx.file.src]
    )

    # outputGroupInfo = OutputGroupInfo(
    #     all = import_depset
    # )

    return [
        DefaultInfo(
            files=js_info_depset,
            runfiles = runfiles
        ),
        js_info(sources = js_info_depset),
        # outputGroupInfo
    ]

####################
jsoo_import = rule(
    implementation = _jsoo_import_impl,
    doc = "Imports js file (e.g. jsoo runtime.js)",
    attrs = dict(
        src = attr.label(
            allow_single_file = [".js"], # True, ## ??
        ),
        # srcs = attr.label_list(
        #     allow_empty = False,
        #     allow_files = [".js"], # True, ## ??
        # ),
    ),
    executable = False,
    provides = [JsInfo],
    toolchains = ["@rules_jsoo//toolchain/type:std"],
)
