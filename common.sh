# common script functionality
# variables exported
#  script_dir = script directory, absolute path

#  build_suffix= suffix of builddir: [webkit1|]-[armel|i386|host]-[m6]

set -e

die() {
    echo "$0: error: $1"
    exit 1
}

is_sbox() {
    if [ -z "$SBOX_UNAME_MACHINE" ]; then
        return 1
    fi
    return 0
}

is_macos() {
    test "$(uname)" == "Darwin"
    return $?
}

if is_macos; then
    readlink() {
        # Assume GNU tools are installed
        greadlink $*
    }
fi

script_file=`readlink -f $0`
script_dir=`dirname $script_file`

shared_dir=$script_dir/..
qt5_dir=$shared_dir/qt5
qtcomponents_dir=$shared_dir/qt-components
webkit_dir=$shared_dir/webkit

#default to host m6 build
device_target=${device_target:-"host"}
meego_target="m6"

d=`dirname $0`

if is_sbox; then
    sudo="fakeroot"
    device_target="$SBOX_DPKG_INST_ARCH"
else
    sudo="sudo"
fi


# export DEB_BUILD_OPTIONS=parallel=30 if you want 30 jobs
parallel_jobs=$(echo $DEB_BUILD_OPTIONS | sed -e 's/.*parallel=\([0-9]\+\).*/\1/')
if [ -n "$parallel_jobs" ]; then
    if [ "$parallel_jobs" = "$DEB_BUILD_OPTIONS" ]; then
	parallel_jobs=""
    fi
fi

if [ -z "$parallel_jobs" ]; then
    if [ -f /proc/cpuinfo ]; then
        parallel_jobs=$(expr $(grep 'processor' /proc/cpuinfo | wc -l) \* 2 + 1)
    fi
fi

if [ -z "$parallel_jobs" ]; then
    # most people have dual-cores..
    parallel_jobs=3
fi

makeargs=${makeargs:-"-j${parallel_jobs}"}
browser_buildmode=debug
webkit_buildmode=--release
webkit_buildmodedir=Release
webkit="qtwebkit-webkit2-dev"
release=
valgrind=
clean=
use_ssh=--ssh
with_icecc=
while [ $# -gt 0 ]; do
    case $1 in
        --release)
            release=1
            browser_buildmode=release
            shift
            ;;
        --webkit_release)
            webkit_buildmode=--release
            webkit_buildmodedir=Release
            shift
            ;;
        --m6)
            meego_target="m6"
            shift
            ;;
        --cross-compile)
            . $script_dir/setup-madde-toolchain.sh
            if [ $? != 0 ]; then
                exit $?
            fi
            device_target=xarmel
            shift
            ;;
        --with-icecc)
            with_icecc=true
            shift
            ;;
        --webkit_debug)
            webkit_buildmode=--debug
	    webkit_buildmodedir=Debug
            shift
            ;;
        --valgrind)
            valgrind=1
            shift
            ;;
        --clean)
            clean=1
            shift
            ;;
	--no-ssh)
	    use_ssh=
	    shift
	    ;;
        *)
            die "unknown flag $1"
            break
            ;;
    esac
done

if [ -n "$with_icecc" -a $device_target=="xarmel" -a -x $script_dir/../setup-icecc-cross-env.sh ]; then
    . $script_dir/../setup-icecc-cross-env.sh
fi


is_release() {
    if [ -z "$release" ]; then
        return 1
    fi
    return
}

qmake_buildmode="CONFIG+=debug CONFIG-=release"
if is_release; then
    qmake_buildmode="CONFIG+=release CONFIG-=debug"
fi

build_suffix=$device_target-$meego_target

qmake_valgrind=""
valgrind_target=""
if [ -n "$valgrind" ]; then
    qmake_valgrind="--qmakearg=CONFIG+=valgrind"
    valgrind_target="-valgrind"
fi

build_suffix=$device_target-$meego_target$valgrind_target


