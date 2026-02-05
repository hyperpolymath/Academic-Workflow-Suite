// SPDX-License-Identifier: PMPL-1.0-or-later
// Documents API - Load, parse, and export TMA documents

use actix_web::{web, HttpResponse, Responder, Scope};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::api::{ErrorResponse, SuccessResponse};
use aws_core::events::EventStore;
use aws_core::tma::{Document, ParsedDocument, StudentInfo};

/// Configure documents routes
pub fn configure() -> Scope {
    web::scope("/documents")
        .route("", web::post().to(load_document))
        .route("/{document_id}", web::get().to(get_document))
        .route("/{document_id}", web::delete().to(delete_document))
        .route("/{document_id}/export", web::post().to(export_document))
        .route("/{document_id}/student", web::get().to(get_student_info))
}

#[derive(Debug, Deserialize)]
pub struct LoadDocumentRequest {
    /// Path to the document file
    pub file_path: String,
    /// Module code (e.g., "TM112")
    pub module: String,
    /// Assignment code (e.g., "TMA01")
    pub assignment: String,
}

#[derive(Debug, Serialize)]
pub struct LoadDocumentResponse {
    pub document_id: Uuid,
    pub student_id_hash: String,
    pub module: String,
    pub assignment: String,
    pub parsed: ParsedDocumentResponse,
}

#[derive(Debug, Serialize)]
pub struct ParsedDocumentResponse {
    pub questions: Vec<QuestionResponse>,
    pub word_count: usize,
    pub metadata: DocumentMetadata,
}

#[derive(Debug, Serialize)]
pub struct QuestionResponse {
    pub question_number: u32,
    pub question_text: String,
    pub answer_text: String,
    pub word_count: usize,
}

#[derive(Debug, Serialize)]
pub struct DocumentMetadata {
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub modified_at: Option<chrono::DateTime<chrono::Utc>>,
    pub author: Option<String>,
}

/// POST /api/v1/documents - Load and parse a document
pub async fn load_document(
    event_store: web::Data<EventStore>,
    request: web::Json<LoadDocumentRequest>,
) -> impl Responder {
    tracing::info!(
        "Loading document from: {} (module: {}, assignment: {})",
        request.file_path,
        request.module,
        request.assignment
    );

    // Parse the document
    let parsed = match Document::parse_from_file(&request.file_path).await {
        Ok(doc) => doc,
        Err(e) => {
            return HttpResponse::BadRequest().json(ErrorResponse::new(
                "ParseError",
                format!("Failed to parse document: {}", e),
            ));
        }
    };

    // Extract student ID and anonymize
    let student_id = match parsed.extract_student_id() {
        Some(id) => id,
        None => {
            return HttpResponse::BadRequest().json(ErrorResponse::new(
                "MissingStudentID",
                "No student ID found in document",
            ));
        }
    };

    let student_id_hash = aws_core::security::anonymize_student_id(&student_id);

    // Generate document ID
    let document_id = Uuid::new_v4();

    // Store document in event store
    if let Err(e) = event_store.store_document_loaded_event(
        document_id,
        &student_id_hash,
        &request.module,
        &request.assignment,
        &parsed,
    ) {
        return HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to store document event: {}", e),
        ));
    }

    // Build response
    let response = LoadDocumentResponse {
        document_id,
        student_id_hash,
        module: request.module.clone(),
        assignment: request.assignment.clone(),
        parsed: ParsedDocumentResponse {
            questions: parsed
                .questions
                .iter()
                .map(|q| QuestionResponse {
                    question_number: q.number,
                    question_text: q.text.clone(),
                    answer_text: q.answer.clone(),
                    word_count: q.answer.split_whitespace().count(),
                })
                .collect(),
            word_count: parsed.total_word_count(),
            metadata: DocumentMetadata {
                created_at: chrono::Utc::now(),
                modified_at: None,
                author: parsed.metadata.author.clone(),
            },
        },
    };

    HttpResponse::Ok().json(SuccessResponse::new(response))
}

/// GET /api/v1/documents/{document_id} - Get document details
pub async fn get_document(
    event_store: web::Data<EventStore>,
    document_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Retrieving document: {}", document_id);

    match event_store.get_document(*document_id) {
        Ok(Some(doc)) => HttpResponse::Ok().json(SuccessResponse::new(doc)),
        Ok(None) => HttpResponse::NotFound().json(ErrorResponse::new(
            "NotFound",
            format!("Document {} not found", document_id),
        )),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to retrieve document: {}", e),
        )),
    }
}

/// DELETE /api/v1/documents/{document_id} - Delete a document
pub async fn delete_document(
    event_store: web::Data<EventStore>,
    document_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Deleting document: {}", document_id);

    match event_store.delete_document(*document_id) {
        Ok(()) => HttpResponse::Ok().json(SuccessResponse::new(serde_json::json!({
            "message": "Document deleted successfully",
            "document_id": document_id.to_string()
        }))),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "DeleteError",
            format!("Failed to delete document: {}", e),
        )),
    }
}

#[derive(Debug, Deserialize)]
pub struct ExportDocumentRequest {
    /// Export format: "docx", "pdf", or "txt"
    pub format: String,
    /// Include feedback in export
    #[serde(default)]
    pub include_feedback: bool,
}

/// POST /api/v1/documents/{document_id}/export - Export document with feedback
pub async fn export_document(
    event_store: web::Data<EventStore>,
    document_id: web::Path<Uuid>,
    request: web::Json<ExportDocumentRequest>,
) -> impl Responder {
    tracing::info!("Exporting document: {} as {}", document_id, request.format);

    // Validate format
    if !["docx", "pdf", "txt"].contains(&request.format.as_str()) {
        return HttpResponse::BadRequest().json(ErrorResponse::new(
            "InvalidFormat",
            format!("Unsupported export format: {}", request.format),
        ));
    }

    // TODO: Implement document export
    HttpResponse::NotImplemented().json(ErrorResponse::new(
        "NotImplemented",
        "Document export is not yet implemented",
    ))
}

/// GET /api/v1/documents/{document_id}/student - Get student info (anonymized)
pub async fn get_student_info(
    event_store: web::Data<EventStore>,
    document_id: web::Path<Uuid>,
) -> impl Responder {
    tracing::info!("Retrieving student info for document: {}", document_id);

    match event_store.get_student_info(*document_id) {
        Ok(Some(info)) => HttpResponse::Ok().json(SuccessResponse::new(info)),
        Ok(None) => HttpResponse::NotFound().json(ErrorResponse::new(
            "NotFound",
            format!("Student info for document {} not found", document_id),
        )),
        Err(e) => HttpResponse::InternalServerError().json(ErrorResponse::new(
            "StorageError",
            format!("Failed to retrieve student info: {}", e),
        )),
    }
}
