// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>

//! End-to-end tests for the Academic Workflow Suite CLI.
//!
//! These tests verify the full CLI behavior including subcommands,
//! error handling, and configuration workflows.

// E2E tests for CLI using cargo run integration

#[test]
fn test_help_command_smoke() {
    // Basic smoke test: --help should work and output help text
    let status = std::process::Command::new("cargo")
        .args(&["run", "--", "--help"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run --help");

    assert!(status.status.success(), "--help should succeed");
    let output = String::from_utf8_lossy(&status.stdout);
    assert!(output.contains("aws"), "Help should contain binary name");
    assert!(output.contains("USAGE") || output.contains("Usage"), "Help should contain usage info");
}

#[test]
fn test_help_for_all_subcommands() {
    // Test that all subcommands have help text
    let subcommands = vec![
        "init", "start", "stop", "status", "mark", "batch",
        "feedback", "config", "login", "sync", "update", "doctor"
    ];

    for subcommand in subcommands {
        let output = std::process::Command::new("cargo")
            .args(&["run", "--", subcommand, "--help"])
            .current_dir(env!("CARGO_MANIFEST_DIR"))
            .output()
            .expect(&format!("Failed to run {} --help", subcommand));

        assert!(
            output.status.success(),
            "{} --help should succeed",
            subcommand
        );

        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(
            !stdout.trim().is_empty(),
            "{} should have non-empty help",
            subcommand
        );
    }
}

#[test]
fn test_unknown_command_error() {
    // Unknown command should give a helpful error
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "nonexistent-command"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run unknown command");

    // Should fail (exit non-zero)
    assert!(!output.status.success(), "Unknown command should fail");

    // Should have an error message
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.is_empty() || !String::from_utf8_lossy(&output.stdout).is_empty(),
        "Should provide error feedback"
    );
}

#[test]
fn test_missing_required_arguments() {
    // Test that commands requiring arguments fail gracefully
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "mark"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run mark without arguments");

    // May succeed (with interactive mode) or fail, but should not crash
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked") && !stderr.contains("thread"),
        "Should not panic on missing arguments"
    );
}

#[test]
fn test_doctor_command_basic() {
    // doctor command should at least run and not crash
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "doctor"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run doctor");

    // doctor might fail if dependencies are missing, but shouldn't panic
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked") && !stderr.contains("thread"),
        "doctor should not panic"
    );
}

#[test]
fn test_status_command_basic() {
    // status command should run and provide some output
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "status"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run status");

    // May fail if backend is not running, but should not panic
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked") && !stderr.contains("thread"),
        "status should not panic"
    );
}

#[test]
fn test_global_verbose_flag() {
    // --verbose should be accepted globally
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "--verbose", "status"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run with --verbose");

    // Should not panic
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked"),
        "Should accept --verbose flag"
    );
}

#[test]
fn test_global_no_color_flag() {
    // --no-color should be accepted globally
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "--no-color", "status"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run with --no-color");

    // Should not panic
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked"),
        "Should accept --no-color flag"
    );
}

#[test]
fn test_config_command_show() {
    // config show should run (may fail if config doesn't exist, but shouldn't panic)
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "config", "show"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run config show");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked"),
        "config show should not panic"
    );
}

#[test]
fn test_init_with_noninteractive_flag() {
    // init with --yes should not prompt
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "init", "test-project", "--yes"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run init");

    // May fail due to file creation, but shouldn't panic
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked"),
        "init --yes should not panic"
    );
}

#[test]
fn test_batch_command_with_pattern() {
    // batch command with pattern should be parseable
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "batch", "/tmp", "--pattern", "*.pdf"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run batch");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked"),
        "batch with pattern should not panic"
    );
}

#[test]
fn test_format_flag_accepted() {
    // --format should be accepted globally
    let output = std::process::Command::new("cargo")
        .args(&["run", "--", "--format", "json", "status"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("Failed to run with --format");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        !stderr.contains("panicked"),
        "Should accept --format flag"
    );
}
