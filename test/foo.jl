using HelFEM

@show HelFEM.helfem.version()

b = HelFEM.RadialBasis(10, 20)
let m = HelFEM.radial_integral(b, 0)
    @show typeof(m) size(m)
end

@show size.(HelFEM.overlap(b, invh=true))
