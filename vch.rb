class Vch < Formula
  desc "Per-task isolated worktrees for parallel Apple development with AI agents"
  homepage "https://github.com/maples7/VibeChard"
  url "https://github.com/Maples7/VibeChard/archive/v1.2.5.tar.gz"
  version "1.2.5"
  sha256 "5a70f81210d77f57a5c63f21666f3ede1ae9b2e558910a39c516a4175034c7b4"
  license "Apache-2.0"

  # Release template: the workflows fill in the source URL, version,
  # checksum and Homebrew-generated bottle block before updating the tap.

  head "https://github.com/maples7/VibeChard.git", branch: "master"

  bottle do
    root_url "https://github.com/Maples7/VibeChard/releases/download/v1.2.5"
    sha256 cellar: :any_skip_relocation, arm64_sonoma: "962ddbe8a3043cc4c417e9a4b129c4627814bdaa36ad9356f2d11bbf4734ae6a"
    sha256 cellar: :any_skip_relocation, sequoia:      "2ddb31b9f4bf1a57e72374c4aeddb0b102990743b7295ccccdbf030ea142b907"
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
