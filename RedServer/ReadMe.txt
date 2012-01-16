Setting Up Project Launchers With AVMGlue:

Byte Compilation with
1. Go to External Tools Configurations
2. Duplicate ASC_compile
3. Change the name to ASC_compile_avmglue
4. In the arguments box paste: -AS3 -strict -import builtin.abc -import toplevel.abc -import avmglue.abc ${resource_loc}

Run Redshell with AVMGlue
1. Go External Tools Config
2. Duplicate redshell_debug
3. Change the name to redshell_debug_avmglue
4. In the arguments box paste: ${resource_loc} ../bin/avmglue.abc