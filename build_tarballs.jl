# Modes:
#
# * julia --project build_tarballs.jl --verbose --devdir=dev --deploy=local
#   Non-interactive local build
#
# * julia --project --color=yes build_tarballs.jl --debug --verbose --deploy="mortenpi/libhelfem_jll.jl"
#   Deploy to GitHub. This requires ENV["GITHUB_TOKEN"] to be set up for authentication.
#
# * julia --project -i build_tarballs.jl
#   Interactive mode, call build_helfem() to run the full local build.
#
# * julia --project -i -e'using Revise; includet("build_tarballs.jl")'
#   Interactive mode, with Revise also called on the main file.

if isinteractive()
    using Revise
end
using BinaryBuilder, Pkg

name = "libhelfem"
version = v"0.0.2-alpha1"
sources = [
    DirectorySource("./src"),
    # The ArchiveSource is replaced with a DirectorySource if a local clone of the HelFEM
    # repository is used.
    if haskey(ENV, "USE_LOCAL_HELFEM")
        @warn "Using local clone of HelFEM"
        @assert isdir(joinpath(@__DIR__, "HelFEM"))
        DirectorySource("./HelFEM", target="HelFEM")
    else
        ArchiveSource(
            "https://github.com/mortenpi/HelFEM/archive/v$version.tar.gz",
            "3f1da9f1ef5f20d4c8c31eed28598f6119e64497b2102110205c07a9e01a6a70"
        )
    end,
]

# $(:version) is a special placeholder string that gets replaced with $version below.
# This needs to be done by hand because we're using raw"" string literals here.
script = raw"""
if [ -d "${WORKSPACE}/srcdir/HelFEM-$(:version)" ]; then
    mv "${WORKSPACE}/srcdir/HelFEM-$(:version)" "${WORKSPACE}/srcdir/HelFEM"
fi
cp -v ${WORKSPACE}/srcdir/CMake.system ${WORKSPACE}/srcdir/HelFEM/CMake.system
# Compile libhelfem as a static library
cd ${WORKSPACE}/srcdir/HelFEM
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DUSE_OPENMP=OFF -B build/ -S .
make -C build/ -j${nproc} helfem
make -C build/ install
# Compile the CxxWrap wrapper as a shared library
cd ${WORKSPACE}/srcdir
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -B build/ -S .
make -C build/ -j${nproc}
make -C build/ install
"""
script = replace(script, raw"$(:version)" => "$version")

#platforms = supported_platforms()
platforms = [
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

products = [
    LibraryProduct("libhelfem-cxxwrap", :libhelfem),
]

dependencies = [
    BuildDependency(PackageSpec(name="Julia_jll",version=v"1.4.1")),
    Dependency(PackageSpec(name = "libcxxwrap_julia_jll", version = "0.8.0")),
    Dependency(PackageSpec(name = "armadillo_jll", version = "9.850.1")),
    Dependency(PackageSpec(name = "GSL_jll", version = "2.6.0")),
    Dependency(PackageSpec(name = "OpenBLAS_jll", version = "0.3.9")),
]

build_helfem() = build_helfem(split("--verbose --devdir=dev --deploy=local x86_64-linux-gnu"))
function build_helfem(args)
    build_tarballs(args, name, version, sources, script, platforms, products, dependencies;
        preferred_gcc_version = v"7.1.0"
    )
end

if isinteractive()
    @info "Running is interactive mode (-i passed). Skipping build_tarballs(), run build_helfem()"
else
    build_helfem(ARGS)
end
