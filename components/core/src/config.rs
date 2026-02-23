// SPDX-License-Identifier: PMPL-1.0-or-later
// Configuration management for AWS Core Engine

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub server: ServerConfig,
    pub database: DatabaseConfig,
    pub security: SecurityConfig,
    pub ai_jail: AIJailConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    #[serde(default = "default_host")]
    pub host: String,
    #[serde(default = "default_port")]
    pub port: u16,
    #[serde(default = "default_cors_origin")]
    pub cors_origin: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DatabaseConfig {
    #[serde(default = "default_db_path")]
    pub path: PathBuf,
    #[serde(default = "default_max_db_size")]
    pub max_size_mb: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityConfig {
    #[serde(default = "default_hash_algorithm")]
    pub hash_algorithm: String,
    #[serde(default = "default_session_salt_length")]
    pub session_salt_length: usize,
    #[serde(default = "default_enable_audit_trail")]
    pub enable_audit_trail: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIJailConfig {
    #[serde(default = "default_ai_jail_socket")]
    pub socket_path: PathBuf,
    #[serde(default = "default_timeout_seconds")]
    pub timeout_seconds: u64,
    #[serde(default = "default_max_retries")]
    pub max_retries: u32,
}

// Default values
fn default_host() -> String {
    "127.0.0.1".to_string()
}

fn default_port() -> u16 {
    8080
}

fn default_cors_origin() -> String {
    "https://localhost".to_string()
}

fn default_db_path() -> PathBuf {
    PathBuf::from("./data/event-store.lmdb")
}

fn default_max_db_size() -> usize {
    1024 // 1GB
}

fn default_hash_algorithm() -> String {
    "SHA3-512".to_string()
}

fn default_session_salt_length() -> usize {
    32
}

fn default_enable_audit_trail() -> bool {
    true
}

fn default_ai_jail_socket() -> PathBuf {
    PathBuf::from("/tmp/aws-ai-jail.sock")
}

fn default_timeout_seconds() -> u64 {
    30
}

fn default_max_retries() -> u32 {
    3
}

impl Config {
    /// Load configuration from environment and config file
    pub fn load() -> Result<Self, config::ConfigError> {
        let config_builder = config::Config::builder()
            // Start with default values
            .set_default("server.host", default_host())?
            .set_default("server.port", default_port() as i64)?
            .set_default("server.cors_origin", default_cors_origin())?
            .set_default("database.path", default_db_path().to_str().unwrap())?
            .set_default("database.max_size_mb", default_max_db_size() as i64)?
            .set_default("security.hash_algorithm", default_hash_algorithm())?
            .set_default("security.session_salt_length", default_session_salt_length() as i64)?
            .set_default("security.enable_audit_trail", default_enable_audit_trail())?
            .set_default("ai_jail.socket_path", default_ai_jail_socket().to_str().unwrap())?
            .set_default("ai_jail.timeout_seconds", default_timeout_seconds() as i64)?
            .set_default("ai_jail.max_retries", default_max_retries() as i64)?
            // Add config file if it exists
            .add_source(config::File::with_name("config/aws-core").required(false))
            // Add environment variables (with prefix AWS_CORE_)
            .add_source(
                config::Environment::with_prefix("AWS_CORE")
                    .separator("__")
                    .try_parsing(true),
            );

        let config = config_builder.build()?;
        config.try_deserialize()
    }

    /// Create a default configuration for testing
    #[cfg(test)]
    pub fn default_test() -> Self {
        Self {
            server: ServerConfig {
                host: default_host(),
                port: 0, // Random port for tests
                cors_origin: "*".to_string(),
            },
            database: DatabaseConfig {
                path: PathBuf::from(":memory:"),
                max_size_mb: 100,
            },
            security: SecurityConfig {
                hash_algorithm: default_hash_algorithm(),
                session_salt_length: default_session_salt_length(),
                enable_audit_trail: true,
            },
            ai_jail: AIJailConfig {
                socket_path: PathBuf::from("/tmp/aws-ai-jail-test.sock"),
                timeout_seconds: default_timeout_seconds(),
                max_retries: default_max_retries(),
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_default_config() {
        let config = Config::default_test();
        assert_eq!(config.server.host, "127.0.0.1");
        assert_eq!(config.security.hash_algorithm, "SHA3-512");
        assert!(config.security.enable_audit_trail);
    }

    #[test]
    fn test_load_config() {
        // This test will use environment variables if set
        let result = Config::load();
        assert!(result.is_ok());
    }
}
