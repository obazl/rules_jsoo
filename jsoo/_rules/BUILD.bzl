def _jsoo_transition_impl(settings, attr):
    # set target platform to vm force inputs to bytecode
    return {"//command_line_option:platforms" : "@ocaml//platforms:vm"}

jsoo_transition = transition(
    implementation = _jsoo_transition_impl,
    inputs = [], outputs = ["//command_line_option:platforms"]
)

