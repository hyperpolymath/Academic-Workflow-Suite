use anyhow::Result;
use colored::*;
use dialoguer::{theme::ColorfulTheme, Confirm, Input, Select};
use std::fs;
use std::path::Path;
use indicatif::{ProgressBar, ProgressStyle};

use crate::api_client::ApiClient;
use crate::models::TmaSubmission;

pub async fn mark_tma_interactive(client: &ApiClient) -> Result<()> {
    loop {
        println!("{}", "Interactive TMA Marking".cyan().bold());
        println!();

        let file_selection = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("Choose how to select the file")
            .items(&["Browse local files", "Enter file path manually"])
            .default(0)
            .interact()?;

        let file_path = if file_selection == 0 {
            let submissions_dir = ".aws/submissions";
            if !Path::new(submissions_dir).exists() {
                fs::create_dir_all(submissions_dir)?;
            }

            let mut files = Vec::new();
            if let Ok(entries) = fs::read_dir(submissions_dir) {
                for entry in entries.flatten() {
                    if entry.path().is_file() {
                        files.push(entry.path().to_string_lossy().to_string());
                    }
                }
            }

            if files.is_empty() {
                println!("{}", "No files found in .aws/submissions/".yellow());
                Input::new().with_prompt("Enter file path").interact_text()?
            } else {
                files.push("Enter path manually...".to_string());
                let selection = Select::with_theme(&ColorfulTheme::default())
                    .with_prompt("Select a file")
                    .items(&files)
                    .default(0)
                    .interact()?;

                if selection == files.len() - 1 {
                    Input::new().with_prompt("Enter file path").interact_text()?
                } else {
                    files[selection].clone()
                }
            }
        } else {
            Input::new().with_prompt("Enter file path").interact_text()?
        };

        if !Path::new(&file_path).exists() {
            println!("{}", format!("File not found: {}", file_path).red());
            continue;
        }

        let student_id: String = Input::new()
            .with_prompt("Student ID (optional)")
            .allow_empty(true)
            .interact_text()?;

        let assignment_id: String = Input::new()
            .with_prompt("Assignment ID (optional)")
            .allow_empty(true)
            .interact_text()?;

        let use_custom_rubric = Confirm::new()
            .with_prompt("Use custom marking rubric?")
            .default(false)
            .interact()?;

        let rubric_path = if use_custom_rubric {
            Some(Input::new().with_prompt("Rubric file path").interact_text()?)
        } else {
            None
        };

        println!();
        let confirm = Confirm::new()
            .with_prompt("Proceed with marking?")
            .default(true)
            .interact()?;

        if !confirm {
            println!("{}", "Cancelled.".yellow());
            return Ok(());
        }

        let pb = ProgressBar::new_spinner();
        pb.set_style(ProgressStyle::default_spinner().template("{spinner:.green} {msg}")?);
        pb.set_message("Uploading and marking TMA...");

        let submission = TmaSubmission {
            student_id: if student_id.is_empty() { None } else { Some(student_id.clone()) },
            assignment_id: if assignment_id.is_empty() { None } else { Some(assignment_id.clone()) },
            file_path: file_path.clone(),
            rubric_path,
            metadata: Default::default(),
        };

        let upload_result = client.upload_tma(&submission).await?;
        let marking_result = client.mark_tma(&upload_result.tma_id).await?;
        pb.finish_and_clear();

        println!("\n{} Grade: {}/100", "✓ Marking complete!".green().bold(), marking_result.grade);

        let feedback_path = format!(".aws/feedback/{}.txt", upload_result.tma_id);
        fs::write(&feedback_path, &marking_result.feedback)?;
        println!("Feedback saved to: {}", feedback_path.yellow());

        let next_action = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("Next action")
            .items(&["Mark another TMA", "Exit"])
            .default(0)
            .interact()?;

        if next_action == 1 {
            break;
        }
    }
    Ok(())
}
