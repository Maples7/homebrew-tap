class Vch < Formula
  desc "Per-task isolated worktrees for parallel Apple development with AI agents"
  homepage "https://github.com/maples7/VibeChard"
  url "https://github.com/Maples7/VibeChard/archive/v1.2.1.tar.gz"
  version "1.2.1"
  sha256 "4a5bce0538f79cc41f9dc64ededd194afff59b53454ee30d5abe689e8032c024"
  license "Apache-2.0"

  # Release template: the workflows fill in the source URL, version,
  # checksum and Homebrew-generated bottle block before updating the tap.

  head "https://github.com/maples7/VibeChard.git", branch: "master"

  bottle do
    root_url "https://github.com/Maples7/VibeChard/releases/download/v1.2.1"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "aa4efb87d71f23bd8c3e6ce700d59a5e038aea7cb3dfb40320491dd7706d99f2"
    sha256 cellar: :any_skip_relocation, sequoia:      "1553ed9cd81b7451508a47532a1f1dbf2766d5f48802f2909fa7bf606c9def60"
  end

  depends_on xcode: ["15.3", :build]
  depends_on macos: :ventura # macOS 13+ floor; matches Package.swift

  def install
    # `--disable-sandbox` is needed because `swift build` writes into
    # `.build/` which Homebrew's sandbox would otherwise block.
    system "swift", "build", "--disable-sandbox", "-c", "release"

    bin.install ".build/release/vch"

    # The shim is libexec-only by design (Q10): keeping it OUT of PATH
    # prevents `which xcodebuild` from accidentally pointing at it
    # before `vch exec` has set up the per-task `.vch/bin` directory.
    libexec.install ".build/release/vch-xcodebuild-shim"

    doc.install "docs/agent-runbook.md"

    # Bash, Zsh, Fish completions auto-generated from the
    # ArgumentParser tree. Standard Homebrew helper.
    generate_completions_from_executable(
      bin/"vch",
      "--generate-completion-script",
      shells: [:bash, :zsh, :fish],
    )
  end

  test do
    # `vch version` exits 0 and mentions itself.
    assert_match "vch", shell_output("#{bin}/vch version")

    # The shim must not leak into PATH.
    refute_path_exists bin/"vch-xcodebuild-shim"
    assert_path_exists libexec/"vch-xcodebuild-shim"

    # Agent runbook is installed and discoverable through the CLI.
    assert_path_exists doc/"agent-runbook.md"
    assert_match (doc/"agent-runbook.md").to_s, shell_output("#{bin}/vch runbook")

    # Completion scripts were installed for every supported shell.
    assert_path_exists bash_completion/"vch"
    assert_path_exists zsh_completion/"_vch"
    assert_path_exists fish_completion/"vch.fish"
  end
end
