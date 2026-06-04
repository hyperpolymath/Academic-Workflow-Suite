// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
use anyhow::{Context, Result};
use reqwest::{multipart, Client, ClientBuilder};
use std::path::Path;
use std::time::Duration;
use crate::models::*;

#[derive(Clone)]
pub struct ApiClient {
    client: Client,
    base_url: String,
}

impl ApiClient {
    pub fn new(base_url: &str) -> Result<Self> {
        let client = ClientBuilder::new()
            .timeout(Duration::from_secs(30))
            .cookie_store(true)
            .build()?;

        Ok(Self {
            client,
            base_url: base_url.trim_end_matches("/").to_string(),
        })
    }

    pub async fn health_check(&self) -> Result<HealthResponse> {
        let url = format!("{}/api/health", self.base_url);
        let response = self.client.get(&url).send().await?;
        Ok(response.json().await?)
    }

    pub async fn upload_tma(&self, submission: &TmaSubmission) -> Result<UploadResponse> {
        let url = format!("{}/api/tma/upload", self.base_url);
        let form = multipart::Form::new()
            .file("file", &submission.file_path).await?
            .text("student_id", submission.student_id.clone().unwrap_or_default())
            .text("assignment_id", submission.assignment_id.clone().unwrap_or_default());
        
        let response = self.client.post(&url).multipart(form).send().await?;
        Ok(response.json().await?)
    }

    pub async fn mark_tma(&self, tma_id: &str) -> Result<MarkingResult> {
        let url = format!("{}/api/tma/{}/mark", self.base_url, tma_id);
        let response = self.client.post(&url).send().await?;
        Ok(response.json().await?)
    }

    pub async fn get_feedback(&self, id: &str) -> Result<Feedback> {
        let url = format!("{}/api/feedback/{}", self.base_url, id);
        let response = self.client.get(&url).send().await?;
        Ok(response.json().await?)
    }

    pub async fn update_feedback(&self, id: &str, content: &str) -> Result<()> {
        let url = format!("{}/api/feedback/{}", self.base_url, id);
        self.client.put(&url).json(&serde_json::json!({ "content": content })).send().await?;
        Ok(())
    }

    pub async fn moodle_login(&self, moodle_url: &str, username: &str, password: &str) -> Result<AuthResponse> {
        let url = format!("{}/api/moodle/login", self.base_url);
        let response = self.client.post(&url)
            .json(&serde_json::json!({ "url": moodle_url, "username": username, "password": password }))
            .send().await?;
        Ok(response.json().await?)
    }

    pub async fn check_moodle_connection(&self) -> Result<bool> {
        let url = format!("{}/api/moodle/status", self.base_url);
        let response = self.client.get(&url).send().await?;
        Ok(response.status().is_success())
    }

    pub async fn get_statistics(&self) -> Result<StatsResponse> {
        let url = format!("{}/api/stats", self.base_url);
        let response = self.client.get(&url).send().await?;
        Ok(response.json().await?)
    }

    pub async fn get_moodle_assignments(&self, _url: &str, _token: &str) -> Result<Vec<Assignment>> {
        let url = format!("{}/api/moodle/assignments", self.base_url);
        let response = self.client.get(&url).send().await?;
        Ok(response.json().await?)
    }

    pub async fn download_submission(&self, remote_url: &str, local_path: &Path) -> Result<()> {
        let response = self.client.get(remote_url).send().await?;
        let content = response.bytes().await?;
        std::fs::write(local_path, content)?;
        Ok(())
    }

    pub async fn upload_moodle_feedback(&self, assignment_id: &str, student_id: &str, feedback: &str) -> Result<()> {
        let url = format!("{}/api/moodle/upload-feedback", self.base_url);
        self.client.post(&url)
            .json(&serde_json::json!({ 
                "assignment_id": assignment_id, 
                "student_id": student_id, 
                "feedback": feedback 
            }))
            .send().await?;
        Ok(())
    }
}
