class Vch < Formula
  desc "Per-task isolated worktrees for parallel Apple development with AI agents"
  homepage "https://github.com/maples7/VibeChard"
  url "https://github.com/Maples7/VibeChard/archive/v1.3.2.tar.gz"
  version "1.3.2"
  sha256 "e0bdc52476756303ee3c42db2682c02c55b41c79351ce2b54e98f970ee520f6a"
  license "Apache-2.0"

  # Release template: the workflows fill in the source URL, version,
  # checksum and Homebrew-generated bottle block before updating the tap.

  head "https://github.com/maples7/VibeChard.git", branch: "master"

  bottle do
    root_url "https://github.com/Maples7/VibeChard/releases/download/v1.3.2"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "adbeb0fb2f61db3e0bcfe057b5d98cb48295ab6eb7881686f7e31018dcb5657a"
    sha256 cellar: :any_skip_relocation, sequoia:       "ce7397e611b6dd2d00deae05932e41c1507c241f3b980f45561664de6fb2eb60"
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
