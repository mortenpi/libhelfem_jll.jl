if isinteractive()
    using Revise
end
using BinaryBuilder, Pkg

name = "libhelfem"
version = v"0.0.1-alpha4"
sources = [
    DirectorySource("./src"),
    DirectorySource("./libhelfem", target="libhelfem"),
]

script = raw"""
pwd
ls -Alh . ${WORKSPACE}/srcdir/libhelfem
# Compile libhelfem as a static library
cd ${WORKSPACE}/srcdir/libhelfem
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON
make -j${nproc}
make install
# Compile the CxxWrap wrapper as a shared library
cd ${WORKSPACE}/srcdir
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

#platforms = supported_platforms()
platforms = [
    #Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

products = [
    LibraryProduct("libhelfem-cxxwrap", :libhelfem),
]

dependencies = [
    BuildDependency(PackageSpec(name="Julia_jll",version=v"1.4.1")),
    Dependency(PackageSpec(name = "libcxxwrap_julia_jll", version = "0.8.0")),
    Dependency(PackageSpec(name = "armadillo_jll", version = "9.850.1")),
]

if isinteractive()
    @info "Running is internative mode (-i passed). Skipping build_tarballs()"
else
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
        preferred_gcc_version = v"7.1.0"
    )
end

function helfem_build_tarballs()
    ARGS = split("--verbose x86_64-linux-gnu")
    build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
        preferred_gcc_version = v"7.1.0"
    )
end

function helfem_export_json()
    ARGS = split("--verbose --meta-json x86_64-linux-gnu")
    pipe = Pipe()
    Base.link_pipe!(pipe; reader_supports_async = true, writer_supports_async = true)
    redirect_stdout(pipe.in) do
        build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies;
            preferred_gcc_version = v"7.1.0"
        )
    end
    s = String(readavailable(pipe))
    close(pipe)
    # @info "Writing to foo.json"
    # open("foo.json", "w") do io
    #     write(io, s)
    # end
    return s
end

function helfem_build_jll(json::AbstractString)
    buff = IOBuffer(strip(json))
    objs = []
    while !eof(buff)
        push!(objs, BinaryBuilder.JSON.parse(buff))
    end
    json_obj = objs[1]

    @info "JSON information" json_obj

    BinaryBuilder.cleanup_merged_object!(json_obj)
    json_obj["dependencies"] = Dependency[dep for dep in json_obj["dependencies"] if !isa(dep, BuildDependency)]
    @info "Calling BinaryBuilder.rebuild_jll_package"
    BinaryBuilder.rebuild_jll_package(
        json_obj, download_dir="products", upload_prefix="mortenpi/libhelfem-cxxwrap",
        code_dir = joinpath(@__DIR__, "dev", "$(json_obj["name"])_jll")
    )
end

function build_helfem()
    helfem_build_tarballs()
    json = helfem_export_json()
    helfem_build_jll(json)
end
