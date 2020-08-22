# Modes:
#
# * julia --project build_tarballs.jl --verbose --devdir=dev --deploy=local
#   Non-interactive local build
#
# * julia --project --color=yes build_tarballs.jl --debug --verbose --deploy="mortenpi/libhelfem_jll.jl"
#   Deploy to GitHub
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
version = v"0.0.1-alpha4"
sources = [
    DirectorySource("./src"),
    DirectorySource("./HelFEM", target="HelFEM"),
]

script = raw"""
cp -v ${WORKSPACE}/srcdir/CMake.system ${WORKSPACE}/srcdir/HelFEM/CMake.system
cat ${WORKSPACE}/srcdir/HelFEM/CMake.system
pwd
ls -Alh . ${WORKSPACE}/srcdir/HelFEM
# Compile libhelfem as a static library
cd ${WORKSPACE}/srcdir/HelFEM
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DCMAKE_POSITION_INDEPENDENT_CODE=ON -B build/ -S .
make -C build/ -j${nproc} helfem
make -C build/ install
ls -Alh $prefix/*
# Compile the CxxWrap wrapper as a shared library
cd ${WORKSPACE}/srcdir
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -B build/ -S .
make -C build/ -j${nproc}
make -C build/ install
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
    @info "Running is internative mode (-i passed). Skipping build_tarballs(), run build_helfem()"
else
    build_helfem(ARGS)
end
