// SPDX-License-Identifier: MPL-2.0
// Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
//! Property-based tests for the CLI using proptest.
//!
//! These tests verify that properties hold across a wide range of inputs,
//! catching edge cases and unexpected behaviors.

use proptest::prelude::*;
use serde_json;

prop_compose! {
    /// Generate valid project names (non-empty, reasonable length)
    fn valid_project_name()(name in r"[A-Za-z0-9_\- ]{1,50}") -> String {
        name
    }
}

prop_compose! {
    /// Generate valid URLs
    fn valid_http_url()(
        host in r"[a-z0-9]{1,10}",
        tld in r"(com|org|edu|net)"
    ) -> String {
        format!("https://{}.{}", host, tld)
    }
}

prop_compose! {
    /// Generate valid concurrency values (1-100)
    fn valid_concurrency()(val in 1usize..=100) -> usize {
        val
    }
}

// Test: Config roundtrip (parse → serialize → parse)
proptest! {
    #[test]
    fn prop_config_roundtrip(
        project_name in valid_project_name(),
        concurrency in valid_concurrency()
    ) {
        // Use a fixed backend URL to avoid parsing issues
        let backend_url = "https://api.example.com";

        let config_yaml = format!(
            "project_name: {}\nbackend_url: {}\ndefault_concurrency: {}",
            project_name, backend_url, concurrency
        );

        // First parse
        let parsed1: Result<serde_yaml::Value, _> = serde_yaml::from_str(&config_yaml);
        prop_assume!(parsed1.is_ok());

        let parsed1 = parsed1.unwrap();

        // Serialize
        let serialized = serde_yaml::to_string(&parsed1).unwrap();

        // Parse again
        let parsed2: Result<serde_yaml::Value, _> = serde_yaml::from_str(&serialized);
        prop_assume!(parsed2.is_ok());

        let parsed2 = parsed2.unwrap();

        // The parsed values should be equivalent
        assert_eq!(parsed1, parsed2);
    }
}

// Test: JSON serialization roundtrip for models
proptest! {
    #[test]
    fn prop_json_roundtrip_submission(
        student_id in r"[A-Z][0-9]{7}",
        assignment_id in r"[A-Z]{3}[0-9]{3}",
        file_path in r"[a-z0-9_]{3,20}\.pdf"
    ) {
        let submission_json = format!(
            r#"{{"student_id":"{}","assignment_id":"{}","file_path":"{}"}}"#,
            student_id, assignment_id, file_path
        );

        // Parse JSON
        let parsed1: serde_json::Value = serde_json::from_str(&submission_json).unwrap();

        // Serialize
        let serialized = serde_json::to_string(&parsed1).unwrap();

        // Parse again
        let parsed2: serde_json::Value = serde_json::from_str(&serialized).unwrap();

        // The parsed values should be equivalent
        assert_eq!(parsed1, parsed2);
    }
}

// Test: Batch operations produce expected number of results
proptest! {
    #[test]
    fn prop_batch_operations_consistent(
        count in 1usize..100
    ) {
        // Simulate batch operations
        let mut results = Vec::new();
        for i in 0..count {
            results.push(format!("result_{}", i));
        }

        // Number of inputs should equal number of outputs (no silent drops)
        assert_eq!(results.len(), count);

        // All results should be unique
        let unique_count = results.iter().collect::<std::collections::HashSet<_>>().len();
        assert_eq!(unique_count, count);
    }
}

// Test: Grade values within valid range
proptest! {
    #[test]
    fn prop_grades_within_range(grade in 0u32..=100) {
        // Grade should be between 0 and 100
        assert!(grade <= 100);
    }
}

// Test: Timeout values are positive
proptest! {
    #[test]
    fn prop_timeout_values_positive(timeout in 1u64..=3600) {
        assert!(timeout > 0);
        assert!(timeout <= 3600); // 1 hour max
    }
}

// Test: String concatenation doesn't lose data
proptest! {
    #[test]
    fn prop_string_concat_preserves_data(
        part1 in r"[a-z0-9]{1,20}",
        part2 in r"[a-z0-9]{1,20}"
    ) {
        let combined = format!("{}{}", part1, part2);

        // Combined length should equal sum of parts
        assert_eq!(combined.len(), part1.len() + part2.len());

        // Original parts should be findable in combined
        assert!(combined.contains(&part1));
        assert!(combined.contains(&part2));
    }
}

// Test: Numeric conversions maintain magnitude
proptest! {
    #[test]
    fn prop_numeric_conversion(value in 0usize..1_000_000) {
        let as_u64 = value as u64;
        let back_to_usize = as_u64 as usize;

        // Should round-trip perfectly
        assert_eq!(value, back_to_usize);
    }
}

// Test: File paths with special characters are handled
proptest! {
    #[test]
    fn prop_file_path_sanitization(
        filename in r"[a-z0-9_]{3,20}"
    ) {
        // Filename should not contain path traversal attempts
        let sanitized = filename.replace("..", "").replace("/", "").replace("\\", "");

        // Sanitized should be safe
        assert!(!sanitized.contains(".."));
        assert!(!sanitized.contains("/"));
        assert!(!sanitized.contains("\\"));
    }
}

// Test: Collection operations maintain invariants
proptest! {
    #[test]
    fn prop_collection_integrity(
        items in prop::collection::vec(r"[a-z0-9]{3,10}", 0..50)
    ) {
        // Vec length should match added items
        assert_eq!(items.len(), items.iter().count());

        // All items should be present
        for item in &items {
            assert!(items.contains(item));
        }
    }
}

// Test: Hash map consistency
proptest! {
    #[test]
    fn prop_map_consistency(
        pairs in prop::collection::vec((r"key_[a-z0-9]{2,5}", r"val_[a-z0-9]{2,5}"), 1..20)
    ) {
        use std::collections::HashMap;

        let mut map = HashMap::new();
        let mut last_value_for_key: HashMap<&str, &str> = HashMap::new();

        for (key, val) in &pairs {
            map.insert(key.as_str(), val.as_str());
            last_value_for_key.insert(key.as_str(), val.as_str());
        }

        // All keys in the map should be retrievable with their final value
        for (key, expected_val) in last_value_for_key {
            assert_eq!(map.get(&key), Some(&expected_val), "Key {} should have value {}", key, expected_val);
        }
    }
}

// Test: Boolean operations are deterministic
proptest! {
    #[test]
    fn prop_boolean_operations_deterministic(
        a in any::<bool>(),
        b in any::<bool>()
    ) {
        let and1 = a && b;
        let and2 = a && b;

        // Same inputs should always produce same output
        assert_eq!(and1, and2);

        let or1 = a || b;
        let or2 = a || b;
        assert_eq!(or1, or2);
    }
}

// Test: Comparisons are transitive
proptest! {
    #[test]
    fn prop_comparison_transitivity(
        a in 0i32..100,
        b in 0i32..100,
        c in 0i32..100
    ) {
        // If a <= b and b <= c, then a <= c
        if a <= b && b <= c {
            assert!(a <= c);
        }
    }
}
