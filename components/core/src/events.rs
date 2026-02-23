//! Event Sourcing System
//!
//! Provides event storage and replay capabilities for the TMA marking system.
//! All state changes are persisted as events in LMDB for complete audit trail.

use anyhow::{Context, Result};
use chrono::{DateTime, Utc};
use heed::{Database, Env, EnvOpenOptions};
use serde::{Deserialize, Serialize};
use std::path::Path;
use uuid::Uuid;

/// Event types in the system
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", content = "data")]
pub enum EventType {
    /// TMA has been submitted for marking
    TMASubmitted {
        student_id: String,
        module_code: String,
        question_number: u32,
        content_hash: String,
    },
    /// Feedback has been generated for a TMA
    FeedbackGenerated {
        tma_id: Uuid,
        feedback: String,
        rubric_scores: Vec<RubricScore>,
    },
    /// Grade has been assigned to a TMA
    GradeAssigned {
        tma_id: Uuid,
        grade: f32,
        max_grade: f32,
    },
    /// Student ID has been anonymized
    StudentAnonymized {
        original_hash: String,
        anonymized_id: String,
        timestamp: DateTime<Utc>,
    },
    /// Document loaded event
    DocumentLoaded {
        document_id: Uuid,
        student_id_hash: String,
        module: String,
        assignment: String,
        word_count: usize,
    },
    /// Document deleted
    DocumentDeleted {
        document_id: Uuid,
    },
    /// Analysis queued
    AnalysisQueued {
        analysis_id: Uuid,
        document_id: Uuid,
        rubric_id: Uuid,
    },
    /// Analysis completed
    AnalysisCompleted {
        analysis_id: Uuid,
        status: String,
    },
    /// Feedback updated
    FeedbackUpdated {
        analysis_id: Uuid,
        tutor_modified: bool,
    },
    /// Feedback accepted
    FeedbackAccepted {
        analysis_id: Uuid,
    },
    /// Feedback rejected
    FeedbackRejected {
        analysis_id: Uuid,
    },
    /// Rubric created
    RubricCreated {
        rubric_id: Uuid,
        module: String,
        assignment: String,
    },
    /// Rubric updated
    RubricUpdated {
        rubric_id: Uuid,
    },
    /// Rubric deleted
    RubricDeleted {
        rubric_id: Uuid,
    },
}

/// Rubric scoring component
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RubricScore {
    pub criterion: String,
    pub score: f32,
    pub max_score: f32,
    pub comment: String,
}

/// An event in the system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Event {
    /// Unique event identifier
    pub id: Uuid,
    /// When the event occurred
    pub timestamp: DateTime<Utc>,
    /// The event type and associated data
    pub event_type: EventType,
    /// Aggregate ID this event relates to (e.g., TMA ID)
    pub aggregate_id: String,
    /// Event version for ordering
    pub version: u64,
}

impl Event {
    /// Create a new event
    pub fn new(event_type: EventType, aggregate_id: String, version: u64) -> Self {
        Self {
            id: Uuid::new_v4(),
            timestamp: Utc::now(),
            event_type,
            aggregate_id,
            version,
        }
    }
}

/// Trait for event storage implementations
pub trait EventStore: Send + Sync {
    /// Append an event to the store
    fn append(&self, event: Event) -> Result<()>;

    /// Get all events for an aggregate
    fn get_events(&self, aggregate_id: &str) -> Result<Vec<Event>>;

    /// Get all events in the system
    fn get_all_events(&self) -> Result<Vec<Event>>;

    /// Get events by type
    fn get_events_by_type(&self, event_type_name: &str) -> Result<Vec<Event>>;

    // High-level domain methods (implemented via events)

    /// Store a document loaded event
    fn store_document_loaded_event(
        &self,
        document_id: Uuid,
        student_id_hash: &str,
        module: &str,
        assignment: &str,
        parsed: &crate::tma::ParsedDocument,
    ) -> Result<()>;

    /// Get document by ID
    fn get_document(&self, document_id: Uuid) -> Result<Option<serde_json::Value>>;

    /// Delete document
    fn delete_document(&self, document_id: Uuid) -> Result<()>;

    /// Get student info for document
    fn get_student_info(&self, document_id: Uuid) -> Result<Option<serde_json::Value>>;

    /// Store analysis queued event
    fn store_analysis_queued_event(
        &self,
        analysis_id: Uuid,
        document_id: Uuid,
        rubric_id: Uuid,
        questions: &[u32],
    ) -> Result<()>;

    /// Get analysis by ID
    fn get_analysis(&self, analysis_id: Uuid) -> Result<Option<serde_json::Value>>;

    /// Get analysis status
    fn get_analysis_status(&self, analysis_id: Uuid) -> Result<Option<String>>;

    /// Get feedback for analysis
    fn get_feedback(&self, analysis_id: Uuid) -> Result<Option<serde_json::Value>>;

    /// Store feedback updated event
    fn store_feedback_updated_event(
        &self,
        analysis_id: Uuid,
        tutor_modified: bool,
    ) -> Result<()>;

    /// Store feedback accepted event
    fn store_feedback_accepted_event(&self, analysis_id: Uuid) -> Result<()>;

    /// Store feedback rejected event
    fn store_feedback_rejected_event(&self, analysis_id: Uuid) -> Result<()>;

    /// Get rubric by ID
    fn get_rubric(&self, rubric_id: Uuid) -> Result<Option<serde_json::Value>>;

    /// List rubrics
    fn list_rubrics(
        &self,
        module: Option<&str>,
        assignment: Option<&str>,
        limit: Option<usize>,
        offset: Option<usize>,
    ) -> Result<Vec<serde_json::Value>>;

    /// Store rubric created event
    fn store_rubric_created_event(
        &self,
        rubric_id: Uuid,
        module: &str,
        assignment: &str,
    ) -> Result<()>;

    /// Store rubric updated event
    fn store_rubric_updated_event(&self, rubric_id: Uuid) -> Result<()>;

    /// Delete rubric
    fn delete_rubric(&self, rubric_id: Uuid) -> Result<()>;
}

/// LMDB-based event store implementation
pub struct LmdbEventStore {
    env: Env,
    db: Database<heed::types::Str, heed::types::SerdeJson<Event>>,
}

impl LmdbEventStore {
    /// Create a new LMDB event store
    ///
    /// # Arguments
    ///
    /// * `path` - Directory path for LMDB database
    /// * `max_size` - Maximum database size in bytes (default: 1GB)
    pub fn new<P: AsRef<Path>>(path: P, max_size: Option<usize>) -> Result<Self> {
        std::fs::create_dir_all(&path)
            .context("Failed to create LMDB directory")?;

        let env = unsafe {
            EnvOpenOptions::new()
                .map_size(max_size.unwrap_or(1024 * 1024 * 1024)) // 1GB default
                .max_dbs(3)
                .open(path)
                .context("Failed to open LMDB environment")?
        };

        let mut wtxn = env.write_txn()
            .context("Failed to create write transaction")?;
        let db = env.create_database(&mut wtxn, Some("events"))
            .context("Failed to create events database")?;
        wtxn.commit()
            .context("Failed to commit database creation")?;

        Ok(Self { env, db })
    }

    /// Generate a unique key for an event
    fn event_key(event: &Event) -> String {
        format!("{}::{}", event.aggregate_id, event.id)
    }
}

impl EventStore for LmdbEventStore {
    fn append(&self, event: Event) -> Result<()> {
        let mut wtxn = self.env.write_txn()
            .context("Failed to create write transaction")?;

        let key = Self::event_key(&event);
        self.db.put(&mut wtxn, &key, &event)
            .context("Failed to write event to LMDB")?;

        wtxn.commit()
            .context("Failed to commit event")?;

        Ok(())
    }

    fn get_events(&self, aggregate_id: &str) -> Result<Vec<Event>> {
        let rtxn = self.env.read_txn()
            .context("Failed to create read transaction")?;

        let mut events = Vec::new();
        let prefix = format!("{}::", aggregate_id);

        for result in self.db.iter(&rtxn)? {
            let (key, event) = result?;
            if key.starts_with(&prefix) {
                events.push(event);
            }
        }

        // Sort by version
        events.sort_by_key(|e| e.version);

        Ok(events)
    }

    fn get_all_events(&self) -> Result<Vec<Event>> {
        let rtxn = self.env.read_txn()
            .context("Failed to create read transaction")?;

        let mut events = Vec::new();
        for result in self.db.iter(&rtxn)? {
            let (_, event) = result?;
            events.push(event);
        }

        // Sort by timestamp
        events.sort_by_key(|e| e.timestamp);

        Ok(events)
    }

    fn get_events_by_type(&self, event_type_name: &str) -> Result<Vec<Event>> {
        let all_events = self.get_all_events()?;

        let filtered = all_events.into_iter()
            .filter(|event| {
                match (&event.event_type, event_type_name) {
                    (EventType::TMASubmitted { .. }, "TMASubmitted") => true,
                    (EventType::FeedbackGenerated { .. }, "FeedbackGenerated") => true,
                    (EventType::GradeAssigned { .. }, "GradeAssigned") => true,
                    (EventType::StudentAnonymized { .. }, "StudentAnonymized") => true,
                    (EventType::DocumentLoaded { .. }, "DocumentLoaded") => true,
                    (EventType::DocumentDeleted { .. }, "DocumentDeleted") => true,
                    (EventType::AnalysisQueued { .. }, "AnalysisQueued") => true,
                    (EventType::AnalysisCompleted { .. }, "AnalysisCompleted") => true,
                    (EventType::FeedbackUpdated { .. }, "FeedbackUpdated") => true,
                    (EventType::FeedbackAccepted { .. }, "FeedbackAccepted") => true,
                    (EventType::FeedbackRejected { .. }, "FeedbackRejected") => true,
                    (EventType::RubricCreated { .. }, "RubricCreated") => true,
                    (EventType::RubricUpdated { .. }, "RubricUpdated") => true,
                    (EventType::RubricDeleted { .. }, "RubricDeleted") => true,
                    _ => false,
                }
            })
            .collect();

        Ok(filtered)
    }

    // High-level domain method implementations

    fn store_document_loaded_event(
        &self,
        document_id: Uuid,
        student_id_hash: &str,
        module: &str,
        assignment: &str,
        parsed: &crate::tma::ParsedDocument,
    ) -> Result<()> {
        let version = self.get_events(&document_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::DocumentLoaded {
                document_id,
                student_id_hash: student_id_hash.to_string(),
                module: module.to_string(),
                assignment: assignment.to_string(),
                word_count: parsed.total_word_count(),
            },
            document_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn get_document(&self, document_id: Uuid) -> Result<Option<serde_json::Value>> {
        let events = self.get_events(&document_id.to_string())?;
        if events.is_empty() {
            return Ok(None);
        }

        // Rebuild document state from events
        let mut doc_data = serde_json::json!({
            "id": document_id,
            "status": "unknown"
        });

        for event in events {
            match &event.event_type {
                EventType::DocumentLoaded {
                    student_id_hash,
                    module,
                    assignment,
                    word_count,
                    ..
                } => {
                    doc_data["status"] = "loaded".into();
                    doc_data["student_id_hash"] = student_id_hash.clone().into();
                    doc_data["module"] = module.clone().into();
                    doc_data["assignment"] = assignment.clone().into();
                    doc_data["word_count"] = (*word_count).into();
                    doc_data["loaded_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::DocumentDeleted { .. } => {
                    doc_data["status"] = "deleted".into();
                    doc_data["deleted_at"] = event.timestamp.to_rfc3339().into();
                }
                _ => {}
            }
        }

        Ok(Some(doc_data))
    }

    fn delete_document(&self, document_id: Uuid) -> Result<()> {
        let version = self.get_events(&document_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::DocumentDeleted { document_id },
            document_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn get_student_info(&self, document_id: Uuid) -> Result<Option<serde_json::Value>> {
        let events = self.get_events(&document_id.to_string())?;
        for event in events {
            match &event.event_type {
                EventType::DocumentLoaded { student_id_hash, .. } => {
                    return Ok(Some(serde_json::json!({
                        "student_id_hash": student_id_hash,
                        "document_id": document_id
                    })));
                }
                _ => {}
            }
        }
        Ok(None)
    }

    fn store_analysis_queued_event(
        &self,
        analysis_id: Uuid,
        document_id: Uuid,
        rubric_id: Uuid,
        _questions: &[u32],
    ) -> Result<()> {
        let version = self.get_events(&analysis_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::AnalysisQueued {
                analysis_id,
                document_id,
                rubric_id,
            },
            analysis_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn get_analysis(&self, analysis_id: Uuid) -> Result<Option<serde_json::Value>> {
        let events = self.get_events(&analysis_id.to_string())?;
        if events.is_empty() {
            return Ok(None);
        }

        // Rebuild analysis state from events
        let mut analysis_data = serde_json::json!({
            "analysis_id": analysis_id,
            "status": "unknown"
        });

        for event in events {
            match &event.event_type {
                EventType::AnalysisQueued {
                    document_id,
                    rubric_id,
                    ..
                } => {
                    analysis_data["status"] = "queued".into();
                    analysis_data["document_id"] = document_id.to_string().into();
                    analysis_data["rubric_id"] = rubric_id.to_string().into();
                    analysis_data["queued_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::AnalysisCompleted { status, .. } => {
                    analysis_data["status"] = status.clone().into();
                    analysis_data["completed_at"] = event.timestamp.to_rfc3339().into();
                }
                _ => {}
            }
        }

        Ok(Some(analysis_data))
    }

    fn get_analysis_status(&self, analysis_id: Uuid) -> Result<Option<String>> {
        let events = self.get_events(&analysis_id.to_string())?;
        if events.is_empty() {
            return Ok(None);
        }

        // Find the most recent status from events
        let mut status = "queued".to_string();
        for event in events {
            match &event.event_type {
                EventType::AnalysisQueued { .. } => {
                    status = "queued".to_string();
                }
                EventType::AnalysisCompleted { status: s, .. } => {
                    status = s.clone();
                }
                _ => {}
            }
        }

        Ok(Some(status))
    }

    fn get_feedback(&self, analysis_id: Uuid) -> Result<Option<serde_json::Value>> {
        let events = self.get_events(&analysis_id.to_string())?;
        if events.is_empty() {
            return Ok(None);
        }

        // Rebuild feedback state from events
        let mut feedback_data = serde_json::json!({
            "analysis_id": analysis_id,
            "status": "pending",
            "feedback_items": [],
            "tutor_modified": false
        });

        for event in events {
            match &event.event_type {
                EventType::AnalysisCompleted { .. } => {
                    feedback_data["generated_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::FeedbackUpdated { tutor_modified, .. } => {
                    feedback_data["tutor_modified"] = (*tutor_modified).into();
                    feedback_data["updated_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::FeedbackAccepted { .. } => {
                    feedback_data["status"] = "accepted".into();
                    feedback_data["accepted_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::FeedbackRejected { .. } => {
                    feedback_data["status"] = "rejected".into();
                    feedback_data["rejected_at"] = event.timestamp.to_rfc3339().into();
                }
                _ => {}
            }
        }

        Ok(Some(feedback_data))
    }

    fn store_feedback_updated_event(
        &self,
        analysis_id: Uuid,
        tutor_modified: bool,
    ) -> Result<()> {
        let version = self.get_events(&analysis_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::FeedbackUpdated {
                analysis_id,
                tutor_modified,
            },
            analysis_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn store_feedback_accepted_event(&self, analysis_id: Uuid) -> Result<()> {
        let version = self.get_events(&analysis_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::FeedbackAccepted { analysis_id },
            analysis_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn store_feedback_rejected_event(&self, analysis_id: Uuid) -> Result<()> {
        let version = self.get_events(&analysis_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::FeedbackRejected { analysis_id },
            analysis_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn get_rubric(&self, rubric_id: Uuid) -> Result<Option<serde_json::Value>> {
        let events = self.get_events(&rubric_id.to_string())?;
        if events.is_empty() {
            return Ok(None);
        }

        // Rebuild rubric from events
        let mut rubric_data = serde_json::json!({
            "id": rubric_id,
            "status": "active"
        });

        for event in events {
            match &event.event_type {
                EventType::RubricCreated {
                    module,
                    assignment,
                    ..
                } => {
                    rubric_data["module"] = module.clone().into();
                    rubric_data["assignment"] = assignment.clone().into();
                    rubric_data["created_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::RubricUpdated { .. } => {
                    rubric_data["updated_at"] = event.timestamp.to_rfc3339().into();
                }
                EventType::RubricDeleted { .. } => {
                    rubric_data["status"] = "deleted".into();
                    rubric_data["deleted_at"] = event.timestamp.to_rfc3339().into();
                    return Ok(None); // Deleted rubrics are not returned
                }
                _ => {}
            }
        }

        Ok(Some(rubric_data))
    }

    fn list_rubrics(
        &self,
        module: Option<&str>,
        assignment: Option<&str>,
        limit: Option<usize>,
        offset: Option<usize>,
    ) -> Result<Vec<serde_json::Value>> {
        // Get all RubricCreated events
        let all_events = self.get_events_by_type("RubricCreated")?;

        // Filter by module and assignment if specified
        let mut rubrics: Vec<serde_json::Value> = Vec::new();

        for event in all_events {
            if let EventType::RubricCreated {
                rubric_id,
                module: event_module,
                assignment: event_assignment,
            } = &event.event_type
            {
                // Apply filters
                if let Some(filter_module) = module {
                    if event_module != filter_module {
                        continue;
                    }
                }
                if let Some(filter_assignment) = assignment {
                    if event_assignment != filter_assignment {
                        continue;
                    }
                }

                // Check if rubric was deleted
                if let Ok(Some(rubric)) = self.get_rubric(*rubric_id) {
                    rubrics.push(rubric);
                }
            }
        }

        // Apply pagination
        let start = offset.unwrap_or(0);
        let end = limit.map(|l| start + l).unwrap_or(rubrics.len());

        Ok(rubrics.into_iter().skip(start).take(end - start).collect())
    }

    fn store_rubric_created_event(
        &self,
        rubric_id: Uuid,
        module: &str,
        assignment: &str,
    ) -> Result<()> {
        let version = self.get_events(&rubric_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::RubricCreated {
                rubric_id,
                module: module.to_string(),
                assignment: assignment.to_string(),
            },
            rubric_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn store_rubric_updated_event(&self, rubric_id: Uuid) -> Result<()> {
        let version = self.get_events(&rubric_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::RubricUpdated { rubric_id },
            rubric_id.to_string(),
            version,
        );
        self.append(event)
    }

    fn delete_rubric(&self, rubric_id: Uuid) -> Result<()> {
        let version = self.get_events(&rubric_id.to_string())?.len() as u64 + 1;
        let event = Event::new(
            EventType::RubricDeleted { rubric_id },
            rubric_id.to_string(),
            version,
        );
        self.append(event)
    }
}

/// Event projection for rebuilding state from events
pub struct EventProjection {
    store: Box<dyn EventStore>,
}

impl EventProjection {
    /// Create a new event projection
    pub fn new(store: Box<dyn EventStore>) -> Self {
        Self { store }
    }

    /// Replay all events for an aggregate
    pub fn replay(&self, aggregate_id: &str) -> Result<Vec<Event>> {
        self.store.get_events(aggregate_id)
    }

    /// Get the current version for an aggregate
    pub fn get_version(&self, aggregate_id: &str) -> Result<u64> {
        let events = self.store.get_events(aggregate_id)?;
        Ok(events.last().map(|e| e.version).unwrap_or(0))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn create_test_store() -> (LmdbEventStore, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let store = LmdbEventStore::new(temp_dir.path(), Some(10 * 1024 * 1024)).unwrap();
        (store, temp_dir)
    }

    #[test]
    fn test_event_creation() {
        let event = Event::new(
            EventType::TMASubmitted {
                student_id: "student123".to_string(),
                module_code: "TM112".to_string(),
                question_number: 1,
                content_hash: "abc123".to_string(),
            },
            "tma-001".to_string(),
            1,
        );

        assert_eq!(event.aggregate_id, "tma-001");
        assert_eq!(event.version, 1);
    }

    #[test]
    fn test_event_store_append_and_retrieve() {
        let (store, _temp_dir) = create_test_store();

        let event = Event::new(
            EventType::TMASubmitted {
                student_id: "student123".to_string(),
                module_code: "TM112".to_string(),
                question_number: 1,
                content_hash: "abc123".to_string(),
            },
            "tma-001".to_string(),
            1,
        );

        store.append(event.clone()).expect("Failed to append event");

        let events = store.get_events("tma-001").expect("Failed to get events");
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].aggregate_id, "tma-001");

        // Explicitly drop to ensure cleanup
        drop(store);
        drop(_temp_dir);
    }

    #[test]
    fn test_event_store_multiple_events() {
        let (store, _temp_dir) = create_test_store();

        let event1 = Event::new(
            EventType::TMASubmitted {
                student_id: "student123".to_string(),
                module_code: "TM112".to_string(),
                question_number: 1,
                content_hash: "abc123".to_string(),
            },
            "tma-001".to_string(),
            1,
        );

        let event2 = Event::new(
            EventType::FeedbackGenerated {
                tma_id: Uuid::new_v4(),
                feedback: "Good work".to_string(),
                rubric_scores: vec![],
            },
            "tma-001".to_string(),
            2,
        );

        store.append(event1).expect("Failed to append event1");
        store.append(event2).expect("Failed to append event2");

        let events = store.get_events("tma-001").expect("Failed to get events");
        assert_eq!(events.len(), 2);
        assert_eq!(events[0].version, 1);
        assert_eq!(events[1].version, 2);

        drop(store);
        drop(_temp_dir);
    }

    #[test]
    fn test_get_events_by_type() {
        let (store, _temp_dir) = create_test_store();

        let event1 = Event::new(
            EventType::TMASubmitted {
                student_id: "student123".to_string(),
                module_code: "TM112".to_string(),
                question_number: 1,
                content_hash: "abc123".to_string(),
            },
            "tma-001".to_string(),
            1,
        );

        let event2 = Event::new(
            EventType::GradeAssigned {
                tma_id: Uuid::new_v4(),
                grade: 85.0,
                max_grade: 100.0,
            },
            "tma-002".to_string(),
            1,
        );

        store.append(event1).expect("Failed to append event1");
        store.append(event2).expect("Failed to append event2");

        let tma_events = store.get_events_by_type("TMASubmitted").expect("Failed to get TMA events");
        assert_eq!(tma_events.len(), 1);

        let grade_events = store.get_events_by_type("GradeAssigned").expect("Failed to get grade events");
        assert_eq!(grade_events.len(), 1);

        drop(store);
        drop(_temp_dir);
    }

    #[test]
    fn test_event_projection() {
        let (store, _temp_dir) = create_test_store();

        let event = Event::new(
            EventType::TMASubmitted {
                student_id: "student123".to_string(),
                module_code: "TM112".to_string(),
                question_number: 1,
                content_hash: "abc123".to_string(),
            },
            "tma-001".to_string(),
            1,
        );

        store.append(event).expect("Failed to append event");

        let projection = EventProjection::new(Box::new(store));
        let version = projection.get_version("tma-001").expect("Failed to get version");
        assert_eq!(version, 1);

        drop(projection);
        drop(_temp_dir);
    }
}
