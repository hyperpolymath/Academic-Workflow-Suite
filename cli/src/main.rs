// SPDX-License-Identifier: PMPL-1.0-or-later

//! Academic Workflow Suite (AWS) — Command Line Interface.
//!
//! This binary provides the primary administrative interface for managing 
//! academic workflows, specifically tailored for Open University (OU) tutors. 
//! It orchestrates the lifecycle of Tutor-Marked Assignments (TMAs), including 
//! ingestion, automated marking assistance, feedback generation, and 
//! synchronization with Moodle.
//!
//! ARCHITECTURE:
//! - **Clap**: High-fidelity CLI argument parsing with subcommand dispatch.
//! - **Tokio**: Asynchronous runtime for concurrent marking and network IO.
//! - **Anyhow**: Semantic error propagation with diagnostic context.
//!
//! WORKFLOW STAGES:
//! 1. `Init`: Scaffolds a new project silo with RSR-compliant manifests.
//! 2. `Login/Sync`: Authenticates with Moodle and retrieves student submissions.
//! 3. `Mark/Batch`: Executes the marking kernel (Julia/Rust) on assignments.
//! 4. `Feedback`: Generates and manages student-facing feedback reports.

use anyhow::Result;
use clap::{Parser, Subcommand};
use colored::*;
use std::process;

mod api_client;
mod commands;
mod config;
mod interactive;
mod models;
mod output;

use commands::*;

/// CLI SCHEMA: Defines the global options and the command-space for AWS.
#[derive(Parser)]
#[command(name = "aws")]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    /// VERBOSITY: Enables detailed logging for troubleshooting.
    #[arg(short, long, global = true)]
    verbose: bool,

    /// APPEARANCE: Disables ANSI color codes for legacy terminals or piping.
    #[arg(long, global = true)]
    no_color: bool,

    /// CONFIGURATION: Explicit path to the `aws.toml` manifest.
    #[arg(short, long, global = true)]
    config: Option<String>,

    /// SERIALIZATION: Switches between human-readable text and JSON output.
    #[arg(long, global = true, default_value = "text")]
    format: String,
}

#[derive(Subcommand)]
enum Commands {
    /// INITIALIZE: Prepares the local environment for a specific module/presentation.
    Init { name: Option<String>, yes: bool },

    /// SERVICE CONTROL: Manages the background worker cluster.
    Start { services: Vec<String>, detach: bool },
    Stop { services: Vec<String>, force: bool },
    Status { detailed: bool },

    /// MARKING: Triggers the analysis of a single TMA file.
    Mark {
        file: Option<String>,
        student: Option<String>,
        assignment: Option<String>,
        interactive: bool,
    },

    /// BATCH: High-concurrency marking of an entire submission directory.
    Batch {
        directory: String,
        #[arg(short, long, default_value = "*.pdf")] pattern: String,
        #[arg(short, long, default_value = "5")] concurrency: usize,
    },

    /// FEEDBACK: CRUD operations for generated student reports.
    Feedback { id: String, edit: bool, output: Option<String> },

    /// CONFIG: Management of the tutor's local preferences and API keys.
    Config { #[command(subcommand)] action: ConfigAction },

    /// AUTHENTICATION: Authenticates the suite with the OU Moodle instance.
    Login { username: Option<String>, url: Option<String>, save: bool },

    /// SYNCHRONIZATION: Bidirectional state sync with the cloud VLE.
    Sync { download: bool, upload: bool, dry_run: bool },

    /// MAINTENANCE: Self-update and system health diagnostics.
    Update { version: Option<String>, check: bool },
    Doctor { fix: bool },
}

/// MAIN ENTRY: Boots the async runtime and dispatches to subcommand handlers.
#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    // POLICY: Enforce no-color mandate if requested.
    if cli.no_color { colored::control::set_override(false); }

    // LOGGING: Configure internal tracing based on verbosity.
    if cli.verbose { std::env::set_var("RUST_LOG", "debug"); }

    // DISPATCH: Routes to the appropriate functional command module.
    let result = match cli.command {
        Commands::Init { name, yes } => init::run(name, yes).await,
        Commands::Start { services, detach } => start::run(services, detach).await,
        Commands::Stop { services, force } => stop::run(services, force).await,
        Commands::Status { detailed } => status::run(detailed).await,
        Commands::Mark { file, student, assignment, interactive } => mark::run(file, student, assignment, interactive).await,
        Commands::Batch { directory, pattern, concurrency } => batch::run(directory, pattern, concurrency).await,
        Commands::Feedback { id, edit, output } => feedback::run(id, edit, output).await,
        Commands::Config { action } => match action {
            ConfigAction::Show => config_cmd::show().await,
            ConfigAction::Set { key, value } => config_cmd::set(key, value).await,
            ConfigAction::Get { key } => config_cmd::get(key).await,
            ConfigAction::Reset { yes } => config_cmd::reset(yes).await,
            ConfigAction::Edit => config_cmd::edit().await,
        },
        Commands::Login { username, url, save } => login::run(username, url, save).await,
        Commands::Sync { download, upload, dry_run } => sync::run(download, upload, dry_run).await,
        Commands::Update { version, check } => update::run(version, check).await,
        Commands::Doctor { fix } => doctor::run(fix).await,
    };

    // ERROR HANDLING: Provides high-signal failure reports with red-bold headers.
    if let Err(e) = result {
        eprintln!("{} {}", "Error:".red().bold(), e);
        if cli.verbose { eprintln!("\n{}\n{:?}", "Backtrace:".yellow(), e); }
        process::exit(1);
    }
}
