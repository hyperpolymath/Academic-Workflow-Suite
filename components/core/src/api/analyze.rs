// SPDX-License-Identifier: PMPL-1.0-or-later
// Analysis API - Trigger AI analysis of TMA submissions

use actix_web::{web, HttpResponse, Responder, Scope};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::api::{ErrorResponse, SuccessResponse};
use aws_core::events::EventStore;

/// Configure analysis routes
pub fn configure() -> Scope {
    web::scope("/analyze")
        .route("", web::post().to(analyze_document))
        .route("/{analysis_id}", web::get().to(get_analysis))
        .route("/{analysis_id}/status", web::get().to(get_analysis_status))
}

#[derive(Debug, Deserialize)]
pub struct AnalyzeRequest {
    /// Document ID to analyze
    pub document_id: Uuid,
    /// Rubric ID to use for analysis
    pub rubric_id: Uuid,
    /// Optional: Specific questions to analyze (default: all)
    #[serde(default)]
    pub questions: Vec<u32>,
}

#[derive(Debug, Serialize)]
pub struct AnalyzeResponse {
    pub analysis_id: Uuid,
    pub document_id: Uuid,
    pub status: AnalysisStatus,
    pub estimated_time_seconds: u32,
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum AnalysisStatus {
    Queued,
    InProgress,
    Completed,
    Failed,
}

#[derive(Debug, Serialize)]
pub struct AnalysisResult {
    pub analysis_id: Uuid,
    pub document_id: Uuid,
    pub rubric_id: Uuid,
    pub status: AnalysisStatus,
    pub started_at: chrono::DateTime<chrono::Utc>,
    pub completed_at: Option<chrono::DateTime<chrono::Utc>>,
    pub feedback: Option<Vec<FeedbackItem>>,
    pub scores: Option<Vec<ScoreItem>>,
    pub total_score: Option<f32>,
    pub error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FeedbackItem {
    pub criterion_id: String,
    pub criterion_name: String,
    pub feedback_text: String,
    pub suggested_score: f32,
    pub max_score: f32,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ScoreItem {
    pub criterion_id: String,
    pub criterion_name: String,
    pub score: f32,
    pub max_score: f32,
}

/// POST /api/v1/analyze - Analyze a document
pub async fn analyze_document(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    request: web::Json<AnalyzeRequest>,
) -> impl Responder {
    tracing::info!(
        "Analyzing document {} with rubric {}",
        request.document_id,
        request.rubric_id
    );

    // Verify document exists
    match event_store.get_document(request.document_id) {
        Ok(Some(_)) => {}
        Ok(None) => {
            return HttpResponse::NotFound().json(ErrorResponse::new(
                "DocumentNotFound",
                format!("Document {} not found", request.document_id),
            ));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(ErrorResponse::new(
                "StorageError",
                format!("Failed to retrieve document: {}", e),
            ));
        }
    }

    // Verify rubric exists
    match event_store.get_rubric(request.rubric_id) {
        Ok(Some(_)) => {}
        Ok(None) => {
            return HttpResponse::NotFound().json(ErrorResponse::new(
                "RubricNotFound",
                format!("Rubric {} not found", request.rubric_id),
            ));
        }
        Err(e) => {
            return HttpResponse::InternalServerError().json(ErrorResponse::new(
                "StorageError",
                format!("Failed to retrieve rubric: {}", e),
            ));
        }
    }

    // Generate analysis ID
    let analysis_id = Uuid::new_v4();

    // Queue analysis task (TODO: Implement actual AI Jail communication)
    // For now, we'll just create a pending analysis
    if let Err(e) = event_store.store_analysis_queued_event(
        analysis_id,
        request.document_id,
        request.rubric_id,
        &request.questions,
    ) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to queue analysis: {}", e),
        ));
    }

    // Estimate time based on document length
    let estimated_time_seconds = 30; // TODO: Calculate based on actual document length

    let response = AnalyzeResponse {
        analysis_id,
        document_id: request.document_id,
        status: AnalysisStatus::Queued,
        estimated_time_seconds,
    };

    HttpResponse::Accepted().json(SuccessResponse::new(response))
}

/// GET /api/v1/analyze/{analysis_id} - Get analysis result
pub async fn get_analysis(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    analysis_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Retrieving analysis: {}", analysis_id);

    match event_store.get_analysis(*analysis_id) {
        Ok(Some(analysis)) => HttpResponse::Ok().json(SuccessResponse::new(analysis)),
        Ok(None) => HttpResponse::NotFound().json(ErrorResponse::new(
            "NotFound",
            format!("Analysis {} not found", analysis_id),
        )),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to retrieve analysis: {}", e),
        )),
    }
}

/// GET /api/v1/analyze/{analysis_id}/status - Get analysis status only
pub async fn get_analysis_status(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    analysis_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Checking analysis status: {}", analysis_id);

    match event_store.get_analysis_status(*analysis_id) {
        Ok(Some(status)) => HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
            "analysis_id": analysis_id.to_string(),
            "status": status,
        }))),
        Ok(None) => HttpResponse::NotFound().json(ErrorResponse::new(
            "NotFound",
            format!("Analysis {} not found", analysis_id),
        )),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to retrieve analysis status: {}", e),
        )),
    }
}
