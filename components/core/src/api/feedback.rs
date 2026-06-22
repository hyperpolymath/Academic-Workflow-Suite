// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
// Feedback API - Manage AI-generated and tutor-edited feedback

use actix_web::{web, HttpResponse, Responder, Scope};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::api::{ErrorResponse, SuccessResponse};
use aws_core::events::EventStore;

pub fn configure() -> Scope {
    web::scope("/feedback")
        .route("/{analysis_id}", web::get().to(get_feedback))
        .route("/{analysis_id}", web::put().to(update_feedback))
        .route("/{analysis_id}/accept", web::post().to(accept_feedback))
        .route("/{analysis_id}/reject", web::post().to(reject_feedback))
}

#[derive(Debug, Serialize)]
pub struct FeedbackResponse {
    pub analysis_id: Uuid,
    pub document_id: Uuid,
    pub feedback_items: Vec<FeedbackItemResponse>,
    pub last_modified: chrono::DateTime<chrono::Utc>,
    pub tutor_modified: bool,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct FeedbackItemResponse {
    pub criterion_id: String,
    pub criterion_name: String,
    pub ai_generated_text: String,
    pub tutor_edited_text: Option<String>,
    pub final_text: String,
    pub suggested_score: f32,
    pub final_score: Option<f32>,
    pub max_score: f32,
    pub status: FeedbackStatus,
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum FeedbackStatus {
    Pending,
    Accepted,
    Edited,
    Rejected,
}

#[derive(Debug, Deserialize)]
pub struct UpdateFeedbackRequest {
    pub updates: Vec<FeedbackUpdate>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct FeedbackUpdate {
    pub criterion_id: String,
    pub edited_text: Option<String>,
    pub final_score: Option<f32>,
}

/// GET /api/v1/feedback/{analysis_id}
pub async fn get_feedback(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    analysis_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Retrieving feedback for analysis: {}", analysis_id);

    match event_store.get_feedback(*analysis_id) {
        Ok(Some(feedback)) => HttpResponse::Ok().json(SuccessResponse::new(feedback)),
        Ok(None) => HttpResponse::NotFound().json(ErrorResponse::new(
            "NotFound",
            format!("Feedback for analysis {} not found", analysis_id),
        )),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to retrieve feedback: {}", e),
        )),
    }
}

/// PUT /api/v1/feedback/{analysis_id}
pub async fn update_feedback(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    analysis_id: web::Path<Uuid>,
    request: web::Json<UpdateFeedbackRequest>,
) -> impl Responder {
    tracing::info!("Updating feedback for analysis: {}", analysis_id);

    // Store that feedback was updated by tutor
    if let Err(e) = event_store.store_feedback_updated_event(*analysis_id, true) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to update feedback: {}", e),
        ));
    }

    HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
        "message": "Feedback updated successfully",
        "analysis_id": analysis_id.to_string()
    })))
}

/// POST /api/v1/feedback/{analysis_id}/accept
pub async fn accept_feedback(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    analysis_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Accepting feedback for analysis: {}", analysis_id);

    if let Err(e) = event_store.store_feedback_accepted_event(*analysis_id) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to accept feedback: {}", e),
        ));
    }

    HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
        "message": "Feedback accepted",
        "analysis_id": analysis_id.to_string()
    })))
}

/// POST /api/v1/feedback/{analysis_id}/reject
pub async fn reject_feedback(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    analysis_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Rejecting feedback for analysis: {}", analysis_id);

    if let Err(e) = event_store.store_feedback_rejected_event(*analysis_id) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to reject feedback: {}", e),
        ));
    }

    HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
        "message": "Feedback rejected",
        "analysis_id": analysis_id.to_string()
    })))
}
