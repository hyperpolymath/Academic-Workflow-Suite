// SPDX-License-Identifier: MPL-2.0
// AWS Core Engine - Main Server Entry Point

use actix_cors::Cors;
use actix_web::{middleware, web, App, HttpServer};
use tracing::{info, warn};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod api;
mod config;
mod graphql;

use crate::config::Config;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "aws_core=debug,actix_web=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    info!("Starting AWS Core Engine");

    // Load configuration
    let config = Config::load().expect("Failed to load configuration");
    let bind_address = format!("{}:{}", config.server.host, config.server.port);

    info!("Server will bind to: {}", bind_address);

    // Initialize event store
    let event_store = aws_core::events::LmdbEventStore::new(
        &config.database.path,
        Some(config.database.max_size_mb * 1024 * 1024),
    )
    .expect("Failed to initialize event store");
    let event_store = web::Data::new(event_store);

    // Initialize GraphQL schema
    let schema = graphql::create_schema(event_store.clone());
    let graphql_schema = web::Data::new(schema);

    info!("Starting HTTP server at http://{}", bind_address);

    // Start HTTP server
    HttpServer::new(move || {
        // Configure CORS
        let cors = Cors::default()
            .allowed_origin(&config.server.cors_origin)
            .allowed_methods(vec!["GET", "POST", "PUT", "DELETE", "OPTIONS"])
            .allowed_headers(vec![
                actix_web::http::header::CONTENT_TYPE,
                actix_web::http::header::AUTHORIZATION,
            ])
            .max_age(3600);

        App::new()
            .app_data(event_store.clone())
            .app_data(graphql_schema.clone())
            // Middleware
            .wrap(middleware::Logger::default())
            .wrap(middleware::Compress::default())
            .wrap(cors)
            .wrap(tracing_actix_web::TracingLogger::default())
            // Health check
            .route("/health", web::get().to(api::health_check))
            // REST API routes
            .service(
                web::scope("/api/v1")
                    .service(api::documents::configure())
                    .service(api::analyze::configure())
                    .service(api::feedback::configure())
                    .service(api::rubrics::configure()),
            )
            // GraphQL endpoint
            .service(
                web::scope("/graphql")
                    .route("", web::post().to(graphql::graphql_handler))
                    .route("", web::get().to(graphql::graphql_playground)),
            )
            // Serve GraphQL Playground in development
            .service(actix_files::Files::new("/playground", "./graphql-playground"))
    })
    .bind(&bind_address)?
    .run()
    .await
}
