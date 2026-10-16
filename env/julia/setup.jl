# setup.jl — build-time Julia environment. Two modes, same logic as env/r/install_packages.R:
# with Manifest.toml -> exact instantiate (reproducible); without -> add the curated list and emit *.generated files.
using Pkg
env = "/opt/env/julia"
Pkg.activate(env)
if isfile(joinpath(env, "Manifest.toml"))
    @info "instantiating pinned Manifest.toml"
    Pkg.instantiate()
else
    pkgs = filter(!isempty, strip.(first.(split.(readlines(joinpath(env, "packages.txt")), '#'))))
    @info "no Manifest.toml: adding $(length(pkgs)) packages" pkgs
    Pkg.add(String.(pkgs))
end
Pkg.precompile()
cp(joinpath(env, "Project.toml"),  joinpath(env, "Project.toml.generated");  force = true)
cp(joinpath(env, "Manifest.toml"), joinpath(env, "Manifest.toml.generated"); force = true)
Pkg.status()
