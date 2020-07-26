using BinaryBuilder, Pkg

name = "libhelfem"
version = v"0.0.1-alpha1"
sources = [
    ArchiveSource(
        "http://s3.mortenpi.eu/massey/helfem/libhelfem-v0.0.1-alpha1.tar.gz",
        "1fd396ad505c2f461381bcbfe3662cc367b81bee90cb68db43a49392439f1fe6",
    ),
]

script = raw"""
cmake -DCMAKE_INSTALL_PREFIX=$prefix -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
make -j${nproc}
make install
"""

#platforms = supported_platforms()
platforms = [
    Linux(:i686, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    Linux(:x86_64, libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
]

products = [
    #LibraryProduct("libhelfem", :libhelfem),
    FileProduct("lib/libhelfem.a", :libhelfem),
]

dependencies = [
    Dependency(PackageSpec(name = "armadillo_jll", version = "9.850")),
]

build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version = v"7.1.0")
