// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
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

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;

    #[test]
    fn test_tma_submission_default() {
        let submission = TmaSubmission::default();
        assert_eq!(submission.file_path, "");
        assert!(submission.student_id.is_none());
        assert!(submission.assignment_id.is_none());
    }

    #[test]
    fn test_tma_submission_construction() {
        let submission = TmaSubmission {
            student_id: Some("S123".to_string()),
            assignment_id: Some("A456".to_string()),
            file_path: "/path/to/submission.pdf".to_string(),
            rubric_path: Some("/path/to/rubric.yml".to_string()),
            metadata: SubmissionMetadata::default(),
        };

        assert_eq!(submission.student_id.unwrap(), "S123");
        assert_eq!(submission.assignment_id.unwrap(), "A456");
        assert_eq!(submission.file_path, "/path/to/submission.pdf");
    }

    #[test]
    fn test_submission_serialization() {
        let submission = TmaSubmission {
            student_id: Some("S123".to_string()),
            assignment_id: Some("A456".to_string()),
            file_path: "/path/to/file.pdf".to_string(),
            rubric_path: None,
            metadata: SubmissionMetadata {
                submitted_at: None,
                file_size: Some(1024),
                file_type: Some("pdf".to_string()),
                checksum: None,
            },
        };

        let json = serde_json::to_string(&submission).expect("should serialize");
        assert!(json.contains("S123"));
        assert!(json.contains("A456"));

        let deserialized: TmaSubmission =
            serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(deserialized.student_id, submission.student_id);
        assert_eq!(deserialized.assignment_id, submission.assignment_id);
    }

    #[test]
    fn test_feedback_construction() {
        let now = Utc::now();
        let feedback = Feedback {
            id: "F123".to_string(),
            tma_id: "TMA456".to_string(),
            content: "Good work!".to_string(),
            grade: 85,
            created_at: now,
            updated_at: None,
            sections: vec![
                FeedbackSection {
                    title: "Strengths".to_string(),
                    content: "Well structured".to_string(),
                    score: Some(8),
                    max_score: Some(10),
                },
                FeedbackSection {
                    title: "Improvements".to_string(),
                    content: "Add more examples".to_string(),
                    score: Some(7),
                    max_score: Some(10),
                },
            ],
        };

        assert_eq!(feedback.id, "F123");
        assert_eq!(feedback.grade, 85);
        assert_eq!(feedback.sections.len(), 2);
    }

    #[test]
    fn test_assignment_status_serialization() {
        let status_open = AssignmentStatus::Open;
        let json = serde_json::to_string(&status_open).unwrap();
        assert_eq!(json, "\"open\"");

        let status_closed = AssignmentStatus::Closed;
        let json = serde_json::to_string(&status_closed).unwrap();
        assert_eq!(json, "\"closed\"");
    }

    #[test]
    fn test_marking_result_construction() {
        let now = Utc::now();
        let result = MarkingResult {
            id: "MR123".to_string(),
            tma_id: "TMA456".to_string(),
            grade: 75,
            feedback: "Good effort".to_string(),
            rubric_scores: vec![
                RubricScore {
                    criterion: "Clarity".to_string(),
                    score: 7,
                    max_score: 10,
                    comment: Some("Well written".to_string()),
                },
            ],
            marked_at: now,
            marker: Some("Marker1".to_string()),
            student_id: Some("S123".to_string()),
            assignment_id: Some("A456".to_string()),
        };

        assert_eq!(result.grade, 75);
        assert_eq!(result.rubric_scores.len(), 1);
        assert_eq!(result.rubric_scores[0].criterion, "Clarity");
    }

    #[test]
    fn test_service_status_construction() {
        let status = ServiceStatus {
            name: "backend".to_string(),
            status: ServiceState::Running,
            uptime: Some(3600),
            version: Some("1.0.0".to_string()),
            health: HealthStatus::Healthy,
        };

        assert_eq!(status.name, "backend");
        assert_eq!(status.uptime, Some(3600));
    }

    #[test]
    fn test_cli_config_default() {
        let config = CliConfig::default();
        assert_eq!(config.output_format, "text");
        assert_eq!(config.color_enabled, true);
        assert_eq!(config.verbose, false);
        assert_eq!(config.api_timeout, 30);
    }

    #[test]
    fn test_auth_response_construction() {
        let now = Utc::now();
        let auth = AuthResponse {
            token: "token123".to_string(),
            expires_at: Some(now),
            username: "user123".to_string(),
            full_name: Some("John Doe".to_string()),
        };

        assert_eq!(auth.token, "token123");
        assert_eq!(auth.username, "user123");
        assert_eq!(auth.full_name.unwrap(), "John Doe");
    }

    #[test]
    fn test_student_construction() {
        let student = Student {
            id: "S123".to_string(),
            name: "Alice Smith".to_string(),
            email: Some("alice@example.com".to_string()),
            course_id: "CS101".to_string(),
        };

        assert_eq!(student.name, "Alice Smith");
        assert_eq!(student.email.unwrap(), "alice@example.com");
    }

    #[test]
    fn test_course_construction() {
        let course = Course {
            id: "C123".to_string(),
            name: "Advanced Algorithms".to_string(),
            code: "CS201".to_string(),
            description: Some("Learn advanced algorithmic techniques".to_string()),
            start_date: None,
            end_date: None,
        };

        assert_eq!(course.code, "CS201");
        assert_eq!(course.description.unwrap(), "Learn advanced algorithmic techniques");
    }
}
