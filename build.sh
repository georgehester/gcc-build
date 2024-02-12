echo_note() {
    echo "\033[96;1mNote\033[0m: $1"
}

echo_error() {
    echo "\033[91;1mError\033[0m: $1"
}

echo_success() {
    echo "\033[92;1mSuccess\033[0m: $1"
}

gcc_version=13.2.0

# Setup paths
build_directory=/tmp/$(whoami)/gcc-${gcc_version}-build/
git_directory=/tmp/$(whoami)/gcc-${gcc_version}-git/
source_directory=/tmp/$(whoami)/gcc-${gcc_version}-source/
install_directory=$(pwd)/build/gcc-${gcc_version}/

# Check if a build exists
if [[ -d $build_directory ]]; then
    rm -rf $build_directory
fi

# Check if a source copy exists
if [[ -d $source_directory ]]; then
    rm -rf $source_directory
fi

# Check if there is a version of the git repo downloaded
if [[ ! -d $git_directory ]]; then
    echo_note "Downloading GCC from git"

    # Clone the git repository
    git clone --branch releases/gcc-${gcc_version} git://gcc.gnu.org/git/gcc.git $git_directory >/dev/null

    # Check if download was successful
    if [[ $? -eq 0 ]]; then
        echo_success "GCC downloaded from git successfully"
    else
        echo_error "Failed to download GCC from git"
        exit 1
    fi
fi

# Create directories that do not exist
for directory in "$build_directory" "$source_directory" "$install_directory"; do
    if [[ ! -d $output_directory ]]; then
        mkdir -p $directory
    fi
done

echo_note "Copying GCC from git"

# Copy the git to source
cp -R $git_directory $source_directory

echo_success "GCC copied from git successfully"

# Download the prerequisites for gcc
echo_note "Downloading prerequisites"

# Move to the gcc root and run the download prerequisites script
cd $source_directory
./contrib/download_prerequisites >/dev/null

# Check if download was successful
if [[ $? -eq 0 ]]; then
    echo_success "Prerequisites downloaded"
else
    echo_error "Failed to download prerequisites"
    exit 1
fi

# Clean up environment variables
echo_note "Cleaning environment"

# Clean environment
RESTORE_USER=$USER
RESTORE_HOME=$HOME

environment_regular_expression="^[0-9A-Za-z_]*$"

# Unset all environment variables
for environment_variable in $(env | awk -F"=" '{print $1}'); do
    if [[ $environment_variable =~ $environment_regular_expression ]]; then
        unset $environment_variable || true
    fi
done

unset environment_regular_expression

# Restore environment
export USER=$RESTORE_USER
export HOME=$RESTORE_HOME
export PATH=/opt/homebrew/opt/binutils/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

echo_success "Environment cleaned"

# Move to the build directory
cd $build_directory

echo_note "Configuring make"

# Set C/C++ flags
CC="gcc"
CXX="g++"
CFLAGS="-02 -Wall -march=x86-64"
CXXFLAGS="-02 -march=x86-64"

#LDFLAGS="-L/opt/homebrew/opt/binutils/lib"
#CPPFLAGS="-I/opt/homebrew/opt/binutils/include"

#export LDFLAGS="-L/opt/homebrew/opt/binutils/lib"
#export CPPFLAGS="-I/opt/homebrew/opt/binutils/include"

#build_machine="aarch64-apple-darwin"
#host_machine=$build_machine
#target_machine="x86_64-unknown-linux-gnu"

build_machine="aarch64-apple-darwin23"
#host_machine="x86_64-unknown-linux-gnu"
target_machine="x86_64-unknown-linux-gnu"

# Run configure script with given params
$source_directory/configure \
    --prefix=${build_directory} \
    --build=${build_machine} \
    --target=${target_machine} \
    --enable-languages=c,c++

#   --enable-standard-branch-protection \
#   --disable-nls \
#   --enable-checking=release \
#   --with-gcc-major-version-only \
#   --enable-languages=c,c++ \
#   --program-suffix=-13 \
#   --with-system-zlib \
#   --build=${build_machine} \
#   --with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX13.sdk

# Check if configuration was successful
if [[ $? -eq 0 ]]; then
    echo_success "Make configuration successful"
else
    echo_error "Failed to set make configuration"
    exit 1
fi

# Build project from source
echo_note "Making"

cd $build_directory

make -j 8 >/dev/null

# Check if make was successful
if [[ $? -eq 0 ]]; then
    echo_success "Make successful"
else
    echo_error "Failed make"
    exit 1
fi
