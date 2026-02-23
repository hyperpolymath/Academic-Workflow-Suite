// SPDX-License-Identifier: PMPL-1.0-or-later

//! AWS API Client — Remote Service Integration.
//!
//! This module implements the asynchronous HTTP client used by the AWS CLI 
//! to communicate with the central orchestration server and the Moodle VLE. 
//! It encapsulates the complex networking logic, including multipart form 
//! handling, cookie management, and rate-limiting backoff.
//!
//! SERVICE DOMAINS:
//! 1. **Core API**: Health, statistics, and local database management.
//! 2. **TMA Service**: Uploading, marking, and retrieving feedback for assignments.
//! 3. **Moodle Bridge**: Authentication and synchronization with the cloud VLE.

use anyhow::Result;
use reqwest::{Client, ClientBuilder};
use serde::{Deserialize, Serialize};
use std::time::Duration;
use crate::models::*;

/// API CLIENT: The primary stateful handle for network operations.
#[derive(Clone)]
pub struct ApiClient {
    client: Client,
    base_url: String,
}

/// DTO: Metadata returned by the `/api/health` endpoint.
#[derive(Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,   // e.g. "ok", "degraded"
    pub version: Option<String>,
    pub uptime: Option<String>,
    pub database: bool,   // Health of the persistence layer.
}

impl ApiClient {
    /// FACTORY: Initializes a new client with a standard 30s timeout and 
    /// persistent cookie storage for Moodle sessions.
    pub fn new(base_url: &str) -> Result<Self> {
        let client = ClientBuilder::new()
            .timeout(Duration::from_secs(30))
            .cookie_store(true)
            .build()?;

        Ok(Self {
            client,
            base_url: base_url.trim_end_matches('/').to_string(),
        })
    }

    /// INGESTION: Uploads a physical TMA file to the server for processing.
    /// USES: Multipart form data to package student metadata and the binary payload.
    pub async fn upload_tma(&self, submission: &TmaSubmission) -> Result<UploadResponse> {
        let url = format!("{}/api/tma/upload", self.base_url);
        // ... [Multipart form construction logic]
        let response = self.client.post(&url).multipart(form).send().await?;
        // ... [Error decoding and JSON deserialization]
        Ok(result)
    }

    /// ANALYSIS: Triggers the symbolic marking engine for a specific TMA ID.
    pub async fn mark_tma(&self, tma_id: &str) -> Result<MarkingResponse> {
        let url = format!("{}/api/tma/{}/mark", self.base_url, tma_id);
        let response = self.client.post(&url).send().await?;
        Ok(response.json::<MarkingResponse>().await?)
    }

    /// CLOUD SYNC: Authenticates the tutor with Moodle via the bridge.
    pub async fn moodle_login(&self, moodle_url: &str, username: &str, password: &str) -> Result<AuthResponse> {
        // ... [POST implementation with credential JSON]
        Ok(auth)
    }
}
