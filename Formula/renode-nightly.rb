class RenodeNightly < Formula
  include Language::Python::Virtualenv

  desc "Antmicro's open source simulation and development framework for embedded systems"
  homepage "https://renode.io"
  url "https://github.com/renode/renode.git",
      revision: "ab8c1936b8c8ab8beb030bddbda1356debf05daf"
  version "1.16.1-20260527"
  license "MIT"

  head "https://github.com/renode/renode.git", branch: "master"

  bottle do
    root_url "builds.renode.io/brew"
    rebuild 44
    sha256 cellar: :any, arm64_tahoe: "b5a897fbda284d608834752230fe20731eaba8c3dae1102a3e2e995f4ee20176"
    sha256 cellar: :any, tahoe:       "7b36b9ced1f2fd32b2816f8cf690e9c8cb08b1e831cadd40fc00d0499dbfbcd8"
  end

  depends_on "binutils" => :build
  depends_on "cmake" => :build
  depends_on "coreutils" => :build
  depends_on "parallel" => :build
  depends_on "dialog"
  depends_on "dotnet@10"
  depends_on "gtk+3"
  depends_on "libyaml"
  depends_on "mono-libgdiplus"
  depends_on "python@3.12"

  conflicts_with "renode", because: "different version of the same package"

  resource "robotframework-retryfailed" do
    url "https://files.pythonhosted.org/packages/4b/99/4ffc2253cbff664c93f4fe63663a0d0a68862c7bbe40aea6f324fd371ef3/robotframework-retryfailed-0.2.0.tar.gz"
    sha256 "c134a924f480e2666916bcb019a7e255d7229bc51a3747e849bd1e7931ed6eb3"
  end

  resource "psutil" do
    url "https://files.pythonhosted.org/packages/de/eb/1c01a34c86ee3b058c556e407ce5b07cb7d186ebe47b3e69d6f152ca5cc5/psutil-5.9.3.tar.gz"
    sha256 "7ccfcdfea4fc4b0a02ca2c31de7fcd186beb9cff8207800e14ab66f79c773af6"
  end

  resource "construct" do
    url "https://files.pythonhosted.org/packages/e0/b7/a4a032e94bcfdff481f2e6fecd472794d9da09f474a2185ed33b2c7cad64/construct-2.10.68.tar.gz"
    sha256 "7b2a3fd8e5f597a5aa1d614c3bd516fa065db01704c72a1efaaeec6ef23d8b45"
  end

  resource "pyelftools" do
    url "https://files.pythonhosted.org/packages/84/05/fd41cd647de044d1ffec90ce5aaae935126ac217f8ecb302186655284fc8/pyelftools-0.30.tar.gz"
    sha256 "2fc92b0d534f8b081f58c7c370967379123d8e00984deb53c209364efd575b40"
  end

  resource "robotframework" do
    url "https://files.pythonhosted.org/packages/b8/70/050b0a5bb51c754ad521d6f1b51c17c293efe65ec72ac955d3686e1afa1d/robotframework-6.1.zip"
    sha256 "a94e0b3c4f8ae08c0a4dc7bff6fa8a51730565103f8c682a2d8391da9a4697f5"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def install
    dotnet = Formula["dotnet@10"]
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

    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"android-arm")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"android-arm64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"android-x64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"android-x86")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"ios-arm")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"ios-arm64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"ios-armv7s")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"iossimulator-x64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"linux-arm")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"maccatalyst-arm64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"maccatalyst-x64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"tvos-arm64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"tvossimulator-x64")
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"win")

    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"linux-arm64") if !OS.linux? || Hardware::CPU.intel?
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"linux-x64") if !OS.linux? || Hardware::CPU.arm?
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"osx-arm64") if !OS.mac? || Hardware::CPU.intel?
    rm_rf (libexec/"output"/"bin"/"Release"/"runtimes"/"osx-x64") if !OS.mac? || Hardware::CPU.arm?

    # Copy licenses to output
    libexec.install "licenses"

    # Setup python enviroment for renode-test
    venv = virtualenv_create(libexec/"venv", "python")
    venv.pip_install resources

    # Create execute scripts
    (bin/"renode").write_env_script (libexec/"renode"),
      DOTNET_ROOT: "${DOTNET_ROOT:-#{dotnet.opt_libexec}}", PATH: "#{dotnet.bin}:$PATH"
    (bin/"renode-test").write_env_script (libexec/"renode-test"),
      DOTNET_ROOT: "${DOTNET_ROOT:-#{dotnet.opt_libexec}}", PATH: "#{dotnet.bin}:#{libexec}/venv/bin:$PATH"
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
