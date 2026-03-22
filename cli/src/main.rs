#![forbid(unsafe_code)]
// SPDX-License-Identifier: PMPL-1.0-or-later

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

#[derive(Parser)]
#[command(name = "aws")]
#[command(author, version, about, long_about = None)]
#[command(propagate_version = true)]
struct Cli {
    #[command(subcommand)]
    command: Commands,

    #[arg(short, long, global = true)]
    verbose: bool,

    #[arg(long, global = true)]
    no_color: bool,

    #[arg(short, long, global = true)]
    config: Option<String>,

    #[arg(long, global = true, default_value = "text")]
    format: String,
}

#[derive(Subcommand)]
pub enum ConfigAction {
    Show,
    Set { key: String, value: String },
    Get { key: String },
    Reset {
        #[arg(short, long)]
        yes: bool,
    },
    Edit,
}

#[derive(Subcommand)]
enum Commands {
    Init { name: Option<String>, yes: bool },
    Start { services: Vec<String>, detach: bool },
    Stop { services: Vec<String>, force: bool },
    Status { detailed: bool },
    Mark {
        file: Option<String>,
        student: Option<String>,
        assignment: Option<String>,
        interactive: bool,
    },
    Batch {
        directory: String,
        #[arg(short, long, default_value = "*.pdf")] pattern: String,
        #[arg(short, long, default_value = "5")] concurrency: usize,
    },
    Feedback { id: String, edit: bool, output: Option<String> },
    Config { #[command(subcommand)] action: ConfigAction },
    Login { username: Option<String>, url: Option<String>, save: bool },
    Sync { download: bool, upload: bool, dry_run: bool },
    Update { version: Option<String>, check: bool },
    Doctor { fix: bool },
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();

    if cli.no_color { colored::control::set_override(false); }
    if cli.verbose { std::env::set_var("RUST_LOG", "debug"); }

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

    if let Err(e) = result {
        eprintln!("{} {}", "Error:".red().bold(), e);
        if cli.verbose { eprintln!("\n{}\n{:?}", "Backtrace:".yellow(), e); }
        process::exit(1);
    }
}
