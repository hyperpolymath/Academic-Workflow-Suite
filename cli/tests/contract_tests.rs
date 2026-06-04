// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Contract / invariant tests for the Academic Workflow Suite CLI.
//!
//! These tests verify structural invariants and interface contracts
//! that must hold regardless of implementation details. They complement
//! unit tests (which check behaviour) and E2E tests (which check full
//! command execution) by checking *what must always be true*.

/// Invariant: The CLI binary name is "aws" (matches the clap name attribute).
///
/// If the binary is renamed the help output must still identify it correctly.
#[test]
fn invariant_binary_name_in_help() {
    let output = std::process::Command::new("cargo")
        .args(["run", "--", "--help"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run --help");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        output.status.success(),
        "Binary must respond to --help"
    );
    assert!(
        stdout.contains("aws"),
        "Contract: binary must identify itself as 'aws' in help output"
    );
}

/// Invariant: All top-level subcommands must expose --help.
///
/// Every user-facing command must be self-documenting. Violation means
/// a command was added without documentation.
#[test]
fn invariant_all_subcommands_are_documented() {
    let required_subcommands = [
        "init", "start", "stop", "status", "mark", "batch",
        "feedback", "config", "login", "sync", "update", "doctor",
    ];

    for subcommand in required_subcommands {
        let output = std::process::Command::new("cargo")
            .args(["run", "--", subcommand, "--help"])
            .current_dir(env!("CARGO_MANIFEST_DIR"))
            .output()
            .unwrap_or_else(|_| panic!("Failed to run '{subcommand} --help'"));

        assert!(
            output.status.success(),
            "Contract: subcommand '{subcommand}' must respond to --help"
        );

        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(
            !stdout.trim().is_empty(),
            "Contract: subcommand '{subcommand}' must have non-empty help text"
        );
    }
}

/// Invariant: Unknown subcommands must produce a non-zero exit code.
///
/// The CLI must not silently swallow unknown inputs — this would hide
/// user typos or outdated scripts.
#[test]
fn invariant_unknown_subcommand_exits_nonzero() {
    let output = std::process::Command::new("cargo")
        .args(["run", "--", "totally-unknown-subcommand-xyzzy"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run with unknown subcommand");

    assert!(
        !output.status.success(),
        "Contract: unknown subcommand must produce a non-zero exit code"
    );
}

/// Invariant: --help produces output on stdout (not stderr).
///
/// Following Unix conventions, help text belongs on stdout so that
/// `aws --help | grep init` works as expected.
#[test]
fn invariant_help_on_stdout() {
    let output = std::process::Command::new("cargo")
        .args(["run", "--", "--help"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run --help");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        !stdout.is_empty(),
        "Contract: --help must write to stdout"
    );
}

/// Invariant: The --no-color flag must be accepted without error.
///
/// Scripts and CI pipelines pass --no-color. If this flag is removed
/// or renamed, every such script silently breaks.
#[test]
fn invariant_no_color_flag_always_accepted() {
    let output = std::process::Command::new("cargo")
        .args(["run", "--", "--no-color", "--help"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run with --no-color");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("error: unexpected argument") && !stderr.contains("panicked"),
        "Contract: --no-color must always be accepted as a global flag"
    );
}

/// Invariant: The --format flag must accept 'json' and 'text' values.
///
/// These are the documented output formats. Removing either breaks
/// existing integrations.
#[test]
fn invariant_format_flag_accepts_documented_values() {
    for format in ["json", "text"] {
        let output = std::process::Command::new("cargo")
            .args(["run", "--", "--format", format, "--help"])
            .current_dir(env!("CARGO_MANIFEST_DIR"))
            .output()
            .unwrap_or_else(|_| panic!("Failed to run with --format {format}"));

        let stderr = String::from_utf8_lossy(&output.stderr);
        assert!(
            !stderr.contains("error: invalid value") && !stderr.contains("panicked"),
            "Contract: --format must accept '{format}' as a valid value"
        );
    }
}

/// Invariant: The CLI must never emit a Rust panic trace to the user.
///
/// Panics are bugs. Every user-visible error path must be handled
/// gracefully with an Error: message, not a panic backtrace.
#[test]
fn invariant_no_panic_on_common_invocations() {
    let invocations: &[&[&str]] = &[
        &["--help"],
        &["status"],
        &["doctor"],
        &["config", "show"],
        &["--no-color", "status"],
        &["--verbose", "status"],
    ];

    for args in invocations {
        let output = std::process::Command::new("cargo")
            .arg("run")
            .arg("--")
            .args(*args)
            .current_dir(env!("CARGO_MANIFEST_DIR"))
            .output()
            .unwrap_or_else(|_| panic!("Failed to run: aws {}", args.join(" ")));

        let stderr = String::from_utf8_lossy(&output.stderr);
        assert!(
            !stderr.contains("panicked at"),
            "Contract: 'aws {}' must not panic — panics are bugs, use Err()",
            args.join(" ")
        );
    }
}

/// Invariant: The --verbose flag must be accepted by all subcommands.
///
/// --verbose is declared as a global flag. Any subcommand that rejects
/// it has broken the global-flag contract.
#[test]
fn invariant_verbose_flag_accepted_globally() {
    let subcommands = ["status", "doctor", "config show"];

    for subcmd in subcommands {
        let mut cmd_args = vec!["run", "--", "--verbose"];
        cmd_args.extend(subcmd.split_whitespace());

        let output = std::process::Command::new("cargo")
            .args(&cmd_args)
            .current_dir(env!("CARGO_MANIFEST_DIR"))
            .output()
            .unwrap_or_else(|_| panic!("Failed to run: aws --verbose {subcmd}"));

        let stderr = String::from_utf8_lossy(&output.stderr);
        assert!(
            !stderr.contains("error: unexpected argument '--verbose'") && !stderr.contains("panicked"),
            "Contract: --verbose must be accepted as a global flag for '{subcmd}'"
        );
    }
}
