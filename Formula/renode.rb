class Renode < Formula
  desc "Antmicro's open source simulation and development framework for embedded systems"
  homepage "https://renode.io"
  url "https://github.com/renode/renode/releases/download/v1.16.0/renode_1.16.0_source.tar.xz"
  sha256 "dab46e73d07a3b1bf2c1cec2c615a37ab85d734dda448296dcdf39c4f7c9451a"
  license "MIT"

  head "https://github.com/renode/renode.git", branch: "master"

  depends_on "binutils" => :build
  depends_on "cmake" => :build
  depends_on "coreutils" => :build
  depends_on "dialog"
  depends_on "dotnet@8"
  depends_on "gtk+3"
  depends_on "mono-libgdiplus"

  def install
    dotnet = Formula["dotnet@8"]
    if Hardware::CPU.arm?
      system "./build.sh", "--net", "--host-arch", "aarch64"
    else
      system "./build.sh", "--net"
    end

    mkdir "licenses"
    if OS.mac?
      system "tools/packaging/common_copy_licenses.sh", "licenses", "macos"
    else
      system "tools/packaging/common_copy_licenses.sh", "licenses", "linux"
    end

    # C# unit tests can not be ran without sources, so remove them
    inreplace "tests/tests.yaml", /^.*csproj$/, ""

    (libexec/"lib"/"resources").install "lib/resources/fonts"
    (libexec/"lib"/"resources").install "lib/resources/libraries"
    (libexec/"lib"/"resources").install "lib/resources/styles"
    libexec.install "output"
    libexec.install "tools"
    libexec.install "platforms"
    libexec.install "scripts"
    libexec.install "tests"
    libexec.install "renode"
    libexec.install "renode-test"
    libexec.install ".renode-root"

    # Remove uneeded files
    rm_r (libexec/"tests"/"unit-tests"/"RenodeTests")

    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"android-arm")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"android-arm64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"android-x64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"android-x86")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"ios-arm")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"ios-arm64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"ios-armv7s")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"iossimulator-x64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"linux-arm")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"maccatalyst-arm64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"maccatalyst-x64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"tvos-arm64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"tvossimulator-x64")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"unix")
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"win")

    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"linux-arm64") if !OS.linux? || Hardware::CPU.intel?
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"linux-x64") if !OS.linux? || Hardware::CPU.arm?
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"osx-arm64") if !OS.mac? || Hardware::CPU.intel?
    rm_r (libexec/"output"/"bin"/"Release"/"runtimes"/"osx-x64") if !OS.mac? || Hardware::CPU.arm?

    # Copy licenses to output
    libexec.install "licenses"

    # Create execute scripts
    (bin/"renode").write_env_script (libexec/"renode"),
      DOTNET_ROOT: "${DOTNET_ROOT:-#{dotnet.opt_libexec}}", PATH: "#{dotnet.bin}:$PATH"
    (bin/"renode-test").write_env_script (libexec/"renode-test"),
      DOTNET_ROOT: "${DOTNET_ROOT:-#{dotnet.opt_libexec}}", PATH: "#{dotnet.bin}:$PATH"
  end

  test do
    # Create a minimal Renode config, as it will otherwise try to create the history file in an inaccessible location
    (testpath/".config").write <<-EOS
      [general]
      history-path = #{testpath}/history
    EOS
    # Run a simple script and verify that the simulation ran
    ENV["RENODE_CI_MODE"] = "YES"
    command = <<-EOS
      #{bin}/renode --console --disable-gui \
      --config #{testpath}/.config \
      -e 'i @scripts/single-node/stm32f4_discovery.resc; \
      emulation RunFor "0.06s"; \
      quit'
    EOS
    output = shell_output(command)
    assert_match "UDP server started", output
  end
end
