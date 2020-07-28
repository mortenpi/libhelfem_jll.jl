@info "Wrapping shared library"
module HelFEM
using CxxWrap, libhelfem_jll
@wrapmodule(libhelfem)
function __init__()
    @initcxx
end
end

@info "Calling functions:"
@show HelFEM.version()

#helfem::utils::get_grid(double rmax, int num_el, int igrid, double zexp)

@show HelFEM.get_grid(40.0, 10, 4, 2.0)
