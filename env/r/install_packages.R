#!/usr/bin/env Rscript
# install_packages.R — build-time installer for the image's R library.
# Why two modes: on the first build there is no lockfile, so we install the curated list from the P3M snapshot that
# rocker pins (ENV CRAN) and emit renv.lock.generated for the maintainer to commit; on every later build we restore
# exactly env/r/renv.lock, which makes the image reproducible and lets CI detect drift with renv::status().
options(warn = 1, Ncpus = max(1L, parallel::detectCores() - 1L))
lib  <- Sys.getenv("RENV_PATHS_LIBRARY", "/usr/local/lib/R/site-library")
here <- "/opt/env/r"
lock <- file.path(here, "renv.lock")

install.packages("renv", lib = lib)

if (file.exists(lock)) {
  message(">> restoring from ", lock)
  renv::restore(project = here, lockfile = lock, library = lib, prompt = FALSE, clean = FALSE)
} else {
  pkgs <- readLines(file.path(here, "packages.txt"), warn = FALSE)
  pkgs <- trimws(sub("#.*$", "", pkgs))
  pkgs <- pkgs[nzchar(pkgs)]
  message(">> no lockfile: installing ", length(pkgs), " packages from ", getOption("repos")[["CRAN"]])
  install.packages(pkgs, lib = lib)
}

missing <- setdiff(
  { p <- readLines(file.path(here, "packages.txt"), warn = FALSE); p <- trimws(sub("#.*$", "", p)); p[nzchar(p)] },
  rownames(installed.packages(lib.loc = lib))
)
if (length(missing)) stop("packages failed to install: ", paste(missing, collapse = ", "))

# Every curated package must actually load (catches binaries linked against missing system libraries, e.g. fs -> libuv).
pkgs_all <- { p <- readLines(file.path(here, "packages.txt"), warn = FALSE); p <- trimws(sub("#.*$", "", p)); p[nzchar(p)] }
bad <- Filter(function(p) !suppressWarnings(suppressPackageStartupMessages(requireNamespace(p, lib.loc = lib, quietly = TRUE))), pkgs_all)
if (length(bad)) stop("packages installed but failed to load: ", paste(bad, collapse = ", "))
message(">> all ", length(pkgs_all), " curated packages load")

# Always emit a fresh snapshot so the maintainer can diff it against the committed lockfile.
renv::snapshot(project = here, library = lib, lockfile = file.path(here, "renv.lock.generated"),
               type = "all", prompt = FALSE, force = TRUE)
message(">> wrote ", file.path(here, "renv.lock.generated"))
