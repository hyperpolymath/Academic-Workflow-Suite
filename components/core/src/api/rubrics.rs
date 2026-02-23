// SPDX-License-Identifier: PMPL-1.0-or-later
// Rubrics API - Manage marking rubrics

use actix_web::{web, HttpResponse, Responder, Scope};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::api::{ErrorResponse, SuccessResponse};
use aws_core::events::EventStore;

pub fn configure() -> Scope {
    web::scope("/rubrics")
        .route("", web::get().to(list_rubrics))
        .route("", web::post().to(create_rubric))
        .route("/{rubric_id}", web::get().to(get_rubric))
        .route("/{rubric_id}", web::put().to(update_rubric))
        .route("/{rubric_id}", web::delete().to(delete_rubric))
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Rubric {
    pub id: Uuid,
    pub name: String,
    pub module: String,
    pub assignment: String,
    pub total_marks: f32,
    pub criteria: Vec<RubricCriterion>,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: Option<chrono::DateTime<chrono::Utc>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RubricCriterion {
    pub id: String,
    pub name: String,
    pub description: String,
    pub max_marks: f32,
    #[serde(default)]
    pub levels: Vec<PerformanceLevel>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PerformanceLevel {
    pub name: String,
    pub description: String,
    pub min_score: f32,
    pub max_score: f32,
}

#[derive(Debug, Deserialize)]
pub struct CreateRubricRequest {
    pub name: String,
    pub module: String,
    pub assignment: String,
    pub total_marks: f32,
    pub criteria: Vec<RubricCriterion>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateRubricRequest {
    pub name: Option<String>,
    pub criteria: Option<Vec<RubricCriterion>>,
}

#[derive(Debug, Deserialize)]
pub struct ListRubricsQuery {
    pub module: Option<String>,
    pub assignment: Option<String>,
    #[serde(default)]
    pub limit: Option<usize>,
    #[serde(default)]
    pub offset: Option<usize>,
}

/// GET /api/v1/rubrics
pub async fn list_rubrics(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    query: web::Query<ListRubricsQuery>,
) -> impl Responder {
    tracing::info!("Listing rubrics (module: {:?}, assignment: {:?})", query.module, query.assignment);

    match event_store.list_rubrics(
        query.module.as_deref(),
        query.assignment.as_deref(),
        query.limit,
        query.offset,
    ) {
        Ok(rubrics) => HttpResponse::Ok().json(SuccessResponse::new(rubrics)),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to list rubrics: {}", e),
        )),
    }
}

/// POST /api/v1/rubrics
pub async fn create_rubric(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    request: web::Json<CreateRubricRequest>,
) -> impl Responder {
    tracing::info!("Creating rubric: {} ({}/{})", request.name, request.module, request.assignment);

    let rubric_id = Uuid::new_v4();
    let rubric = Rubric {
        id: rubric_id,
        name: request.name.clone(),
        module: request.module.clone(),
        assignment: request.assignment.clone(),
        total_marks: request.total_marks,
        criteria: request.criteria.clone(),
        created_at: chrono::Utc::now(),
        updated_at: None,
    };

    if let Err(e) = event_store.store_rubric_created_event(rubric.id, &rubric.module, &rubric.assignment) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to create rubric: {}", e),
        ));
    }

    HttpResponse::Created().json(SuccessResponse::new(rubric))
}

/// GET /api/v1/rubrics/{rubric_id}
pub async fn get_rubric(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    rubric_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Retrieving rubric: {}", rubric_id);

    match event_store.get_rubric(*rubric_id) {
        Ok(Some(rubric)) => HttpResponse::Ok().json(SuccessResponse::new(rubric)),
        Ok(None) => HttpResponse::NotFound().json(ErrorResponse::new(
            "NotFound",
            format!("Rubric {} not found", rubric_id),
        )),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to retrieve rubric: {}", e),
        )),
    }
}

/// PUT /api/v1/rubrics/{rubric_id}
pub async fn update_rubric(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    rubric_id: web::Path<Uuid>,
    request: web::Json<UpdateRubricRequest>,
) -> impl Responder {
    tracing::info!("Updating rubric: {}", rubric_id);

    if let Err(e) = event_store.store_rubric_updated_event(*rubric_id) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to update rubric: {}", e),
        ));
    }

    HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
        "message": "Rubric updated successfully",
        "rubric_id": rubric_id.to_string()
    })))
}

/// DELETE /api/v1/rubrics/{rubric_id}
pub async fn delete_rubric(
    event_store: web::Data<aws_core::events::LmdbEventStore>,
    rubric_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Deleting rubric: {}", rubric_id);

    match event_store.delete_rubric(*rubric_id) {
        Ok(()) => HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
            "message": "Rubric deleted successfully",
            "rubric_id": rubric_id.to_string()
        }))),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "DeleteError",
            format!("Failed to delete rubric: {}", e),
        )),
    }
}
