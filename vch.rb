class Vch < Formula
  desc "Per-task isolated worktrees for parallel Apple development with AI agents"
  homepage "https://github.com/maples7/VibeChard"
  url "https://github.com/Maples7/VibeChard/archive/v1.3.1.tar.gz"
  version "1.3.1"
  sha256 "7f18d22aacc8f1acb7e23377a980a775c8256c3731e1e8d3998ab293abca8f40"
  license "Apache-2.0"

  # Release template: the workflows fill in the source URL, version,
  # checksum and Homebrew-generated bottle block before updating the tap.

  head "https://github.com/maples7/VibeChard.git", branch: "master"

  bottle do
    root_url "https://github.com/Maples7/VibeChard/releases/download/v1.3.1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "148ba401813747d51867b45193ede86274d96bd237a3b428ecb46456b6019abf"
    sha256 cellar: :any_skip_relocation, sequoia:       "456fbe7c3a2889f7a53466040e4f9c2620a69eee1868f23d6314c067bac875ba"
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
