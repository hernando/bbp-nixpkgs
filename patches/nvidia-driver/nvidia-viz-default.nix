{ stdenv, fetchurl, kernel ? null, xorg, zlib, perl
, gtk, atk, pango, glib, gdk_pixbuf, cairo, nukeReferences
, # Whether to build the libraries only (i.e. not the kernel module or
  # nvidia-settings).  Used to support 32-bit binaries on 64-bit
  # Linux.
  libsOnly ? false
}:

with stdenv.lib;

assert (!libsOnly) -> kernel != null;

let

  versionNumber = "367.57";

  # Policy: use the highest stable version as the default (on our master).
  inherit (stdenv.lib) makeLibraryPath;

in

stdenv.mkDerivation {
  name = "nvidia-x11-${versionNumber}${optionalString (!libsOnly) "-${kernel.version}"}";

  builder = ./nvidia-viz-builder.sh;

  src =
    if stdenv.system == "i686-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86/${versionNumber}/NVIDIA-Linux-x86-${versionNumber}.run";
        sha256 = "0vxrx2hmycvhyp32mapf1vv01ddlghliwsvkhsg29hv3a7fl4i28";
      }
    else if stdenv.system == "x86_64-linux" then
      fetchurl {
        url = "http://us.download.nvidia.com/XFree86/Linux-x86_64/${versionNumber}/NVIDIA-Linux-x86_64-${versionNumber}-no-compat32.run";
        sha256 = "1r6nbm201psrs4xxw8826kl1li10wbhjbfwvp924ninsl6v8ljmr";
      }
    else throw "nvidia-x11 does not support platform ${stdenv.system}";

  inherit versionNumber libsOnly;
  inherit (stdenv) system;

  kernel = if libsOnly then null else kernel.dev;

  dontStrip = true;

  glPath      = makeLibraryPath [xorg.libXext xorg.libX11 xorg.libXrandr];
  cudaPath    = makeLibraryPath [zlib stdenv.cc.cc];
  openclPath  = makeLibraryPath [zlib];
  allLibPath  = makeLibraryPath [xorg.libXext xorg.libX11 xorg.libXrandr zlib stdenv.cc.cc];

  gtkPath = optionalString (!libsOnly) (makeLibraryPath
    [ gtk atk pango glib gdk_pixbuf cairo ] );
  programPath = makeLibraryPath [ xorg.libXv ];

  buildInputs = [ perl nukeReferences ];

  disallowedReferences = if libsOnly then [] else [ kernel.dev ];

  meta = with stdenv.lib.meta; {
    homepage = http://www.nvidia.com/object/unix.html;
    description = "X.org driver and kernel module for NVIDIA graphics cards";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
    maintainers = [ maintainers.vcunat ];
    priority = 4; # resolves collision with xorg-server's "lib/xorg/modules/extensions/libglx.so"
  };
}
