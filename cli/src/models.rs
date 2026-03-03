use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TmaSubmission {
    pub student_id: Option<String>,
    pub assignment_id: Option<String>,
    pub file_path: String,
    pub rubric_path: Option<String>,
    #[serde(default)]
    pub metadata: SubmissionMetadata,
}

impl Default for TmaSubmission {
    fn default() -> Self {
        Self {
            student_id: None,
            assignment_id: None,
            file_path: String::new(),
            rubric_path: None,
            metadata: SubmissionMetadata::default(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SubmissionMetadata {
    pub submitted_at: Option<DateTime<Utc>>,
    pub file_size: Option<u64>,
    pub file_type: Option<String>,
    pub checksum: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Feedback {
    pub id: String,
    pub tma_id: String,
    pub content: String,
    pub grade: u32,
    pub created_at: DateTime<Utc>,
    pub updated_at: Option<DateTime<Utc>>,
    pub sections: Vec<FeedbackSection>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FeedbackSection {
    pub title: String,
    pub content: String,
    pub score: Option<u32>,
    pub max_score: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MoodleSubmission {
    pub student_id: String,
    pub url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Assignment {
    pub id: String,
    pub name: String,
    pub description: Option<String>,
    pub due_date: Option<DateTime<Utc>>,
    pub max_grade: u32,
    pub course_id: String,
    pub submissions: Vec<MoodleSubmission>,
    pub status: AssignmentStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum AssignmentStatus {
    Open,
    Closed,
    Draft,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Student {
    pub id: String,
    pub name: String,
    pub email: Option<String>,
    pub course_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarkingResult {
    pub id: String,
    pub tma_id: String,
    pub grade: u32,
    pub feedback: String,
    pub rubric_scores: Vec<RubricScore>,
    pub marked_at: DateTime<Utc>,
    pub marker: Option<String>,
    pub student_id: Option<String>,
    pub assignment_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RubricScore {
    pub criterion: String,
    pub score: u32,
    pub max_score: u32,
    pub comment: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Course {
    pub id: String,
    pub name: String,
    pub code: String,
    pub description: Option<String>,
    pub start_date: Option<DateTime<Utc>>,
    pub end_date: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceStatus {
    pub name: String,
    pub status: ServiceState,
    pub uptime: Option<u64>,
    pub version: Option<String>,
    pub health: HealthStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ServiceState {
    Running,
    Stopped,
    Starting,
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum HealthStatus {
    Healthy,
    Unhealthy,
    Degraded,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    pub last_sync: Option<DateTime<Utc>>,
    pub sync_status: String,
    pub items_synced: u32,
    pub errors: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CliConfig {
    pub output_format: String,
    pub color_enabled: bool,
    pub verbose: bool,
    pub api_timeout: u64,
}

impl Default for CliConfig {
    fn default() -> Self {
        Self {
            output_format: "text".to_string(),
            color_enabled: true,
            verbose: false,
            api_timeout: 30,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UploadResponse {
    pub id: String,
    pub tma_id: String,
    pub status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MarkingResponse {
    pub result: MarkingResult,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuthResponse {
    pub token: String,
    pub expires_at: Option<DateTime<Utc>>,
    pub username: String,
    pub full_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthResponse {
    pub status: String,
    pub version: Option<String>,
    pub uptime: Option<String>,
    pub database: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatsResponse {
    pub total_marked: u32,
    pub pending_reviews: u32,
    pub average_grade: f32,
    pub last_sync: Option<String>,
}
