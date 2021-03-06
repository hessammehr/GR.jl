function check_grdir()
    if "GRDIR" in keys(ENV)
        have_dir = length(ENV["GRDIR"]) > 0
    elseif isdir(joinpath(homedir(), "gr"), "fonts")
        have_dir = true
    else
        have_dir = false
        for d in ("/opt", "/usr/local", "/usr")
            if isdir(joinpath(d, "gr", "fonts"))
                have_dir = true
                break
            end
        end
    end
    have_dir
end

function get_version()
    version = v"0.31.0"
    try
        v = Pkg.installed("GR")
        if string(v)[end:end] == "+"
            version = "latest"
        end
    end
    version
end

if !check_grdir()
  if Sys.KERNEL == :NT
    os = :Windows
  else
    os = Sys.KERNEL
  end
  const arch = Sys.ARCH
  if os == :Linux && arch == :x86_64
    if isfile("/etc/redhat-release")
      rel = String(read(pipeline(`cat /etc/redhat-release`, `sed s/.\*release\ //`, `sed s/\ .\*//`)))[1:end-1]
      if rel > "7.0"
        os = "Redhat"
      end
    elseif isfile("/etc/os-release")
      id = String(read(pipeline(`cat /etc/os-release`, `grep ^ID=`, `cut -d= -f2`)))[1:end-1]
      if id == "debian"
        os = "Debian"
      elseif id == "ubuntu"
        os = "Ubuntu"
      end
    end
  end
  version = get_version()
  tarball = "gr-$version-$os-$arch.tar.gz"
  if !isfile("downloads/$tarball")
    info("Downloading pre-compiled GR $version $os binary")
    url = "gr-framework.org/downloads/$tarball"
    file = "downloads/$tarball"
    mkpath("downloads")
    try
      download("https://$url", file)
    catch
      info("Using insecure connection")
      download("http://$url", file)
    end
    if os == :Windows
      home = (VERSION < v"0.7") ? JULIA_HOME : Sys.BINDIR
      success(`$home/7z x downloads/$tarball -y`)
      rm("downloads/$tarball")
      tarball = tarball[1:end-3]
      success(`$home/7z x $tarball -y -ttar`)
      rm("$tarball")
    else
      run(`tar xzf downloads/$tarball`)
      rm("downloads/$tarball")
    end
  end
  if os == :Darwin
    app = joinpath("gr", "Applications", "GKSTerm.app")
    run(`/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f $app`)
    try
      @eval import QML
      if Pkg.installed("QML") != nothing
        qt = QML.qt_prefix_path()
        path = joinpath(qt, "Frameworks")
        if isdir(path)
          qt5plugin = joinpath(pwd(), "gr", "lib", "qt5plugin.so")
          run(`install_name_tool -add_rpath $path $qt5plugin`)
          println("Using Qt ", splitdir(qt)[end], " at ", qt)
        end
      end
    end
  end
end
