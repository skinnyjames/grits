package("git2")
  add_deps("cmake")
  set_kind("static")
  set_policy("package.install_always", true)
  add_versions("v1.3.0", "192eeff84596ff09efb6b01835a066f2df7cd7985e0991c79595688e6b36444e")
  add_urls("https://github.com/libgit2/libgit2/archive/refs/tags/$(version).tar.gz")
  on_install(function(package)
    os.mkdir("build")
    os.cd("build")
    os.execv(string.format("cmake .. -DCMAKE_INSTALL_PREFIX=%s/vendor", os.projectdir()))
    os.execv("cmake --build . --target install")
  end)
package_end()
