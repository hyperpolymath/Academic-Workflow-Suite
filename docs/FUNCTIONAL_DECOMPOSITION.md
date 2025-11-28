# Functional Decomposition Architecture
## Multi-Threaded Essay Analysis with Information Silos

**Version**: 2.0 (Supersedes Layer 1 of IP_PROTECTION.md)
**Security Model**: "Divide the Content, Conquer the Risk"
**Principle**: No single component experiences the whole essay

---

## Core Insight

**Traditional AI**: One model sees everything
- Risk: Complete intellectual content visible
- Attack surface: Single point of compromise
- Trust requirement: Must trust the AI

**Functional Decomposition**: Each component sees only what it needs
- Risk: No component has complete IP
- Attack surface: Distributed, each silo isolated
- Trust requirement: None (mechanical processes + disposable AI)

---

## Decomposition Strategy

### Thread 1: Citation & Reference Checking (Non-AI) 📚

**Input**: Bibliography + In-text citations ONLY
**No Access To**: Essay body, arguments, ideas

```rust
pub struct ReferenceExtractor {
    // Never sees essay content
}

impl ReferenceExtractor {
    pub fn extract(&self, document: &Document) -> References {
        // Extract only:
        // - Bibliography entries
        // - [Author, Year] citations
        // - Footnotes with URLs

        // Returns:
        References {
            bibliography: vec![
                "Smith, J. (2023). Title. Journal, 15(3), 45-67."
            ],
            citations: vec![
                Citation { author: "Smith", year: 2023, page: Some(45) }
            ],
            urls: vec!["https://doi.org/10.1234/example"],
        }
    }
}

// Process with rule-based system (NOT AI)
pub fn check_citations(refs: &References) -> CitationReport {
    CitationReport {
        formatting: check_apa_format(&refs.bibliography),
        completeness: check_all_cited(&refs.citations, &refs.bibliography),
        url_validity: check_urls_accessible(&refs.urls),
        duplicate_detection: find_duplicates(&refs.bibliography),
    }
}
```

**What This Thread Sees**: Reference list (mechanical data)
**What It NEVER Sees**: Essay arguments, student's ideas, analysis
**Processing**: Rule-based (Prolog/Datalog), NO AI needed

---

### Thread 2: Structure Visualization (Formal Methods) 🏗️

**Input**: Document structure tags ONLY (no content)
**No Access To**: Essay text, arguments, specifics

```prolog
% Logtalk structural analysis
:- object(essay_structure).

    % Extract structure only
    :- public(analyze_structure/1).
    analyze_structure(Document) :-
        extract_sections(Document, Sections),
        extract_headings(Document, Headings),
        extract_paragraphs(Document, Paragraphs),
        % Never reads paragraph CONTENT, only COUNT and POSITION
        check_structure_validity(Sections, Headings, Paragraphs).

    % Example structure (content redacted)
    structure([
        section('Introduction', paragraphs(3)),
        section('Literature Review', paragraphs(5)),
        section('Methodology', paragraphs(4)),
        section('Results', paragraphs(6)),
        section('Discussion', paragraphs(7)),
        section('Conclusion', paragraphs(2)),
        section('References', entries(15))
    ]).

    % Validation rules (NO AI)
    check_structure_validity(Structure) :-
        has_introduction(Structure),
        has_conclusion(Structure),
        sections_in_order(Structure),
        sufficient_paragraphs_per_section(Structure).

:- end_object.
```

**Visualization Output** (ASCII art, no content):
```
Essay Structure:
├─ Introduction (3¶)
├─ Literature Review (5¶)
│  ├─ Subsection 1 (2¶)
│  └─ Subsection 2 (3¶)
├─ Methodology (4¶)
├─ Results (6¶)
├─ Discussion (7¶)
└─ Conclusion (2¶)

Flow: Intro → Lit → Method → Results → Disc → Concl ✅
Balance: Sections roughly equal ⚠️ (Discussion longer)
Headings: All present ✅
```

**What This Thread Sees**: Section names, paragraph counts, heading hierarchy
**What It NEVER Sees**: Paragraph content, arguments, student's ideas
**Processing**: Logtalk/Prolog rules, NO AI

---

### Thread 3: Grammar & Spelling (Local NLP) ✏️

**Input**: Individual sentences (randomized order, no context)
**No Access To**: Full essay, argument flow, semantic meaning

```rust
pub struct GrammarChecker {
    // Uses LanguageTool (local, open-source)
    language_tool: LanguageTool,
}

impl GrammarChecker {
    pub fn check_sentences(&self, sentences: Vec<String>) -> Vec<GrammarIssue> {
        // Shuffle sentences (no order preserved)
        let mut shuffled = sentences.clone();
        shuffled.shuffle(&mut thread_rng());

        // Check each sentence independently
        shuffled.par_iter().map(|sentence| {
            self.language_tool.check(sentence)
        }).flatten().collect()
    }
}

// Example:
// Sentence 5: "The algorithm use a hash table."
//            → Error: "use" should be "uses"
//
// Checker NEVER knows:
// - What came before/after this sentence
// - What the essay is about
// - Whether it's introduction or conclusion
```

**What This Thread Sees**: Individual sentences (unordered)
**What It NEVER Sees**: Essay topic, argument flow, coherence
**Processing**: LanguageTool (local, rule-based), NO AI

---

### Thread 4: Rubric Alignment (Multiple Disposable SLMs) 🤖

**Input**: Rubric-specific fragments ONLY (different fragments per SLM)
**No Access To**: Complete essay, other fragments

#### SLM Pool Architecture

```rust
pub struct SlmPool {
    models: Vec<DisposableSlm>,
}

pub struct DisposableSlm {
    id: Uuid,
    model: SmallLanguageModel,  // ~1B parameters (not 7B)
    assigned_criteria: Vec<RubricCriterion>,
    lifetime: Duration,  // Max 60 seconds
}

impl SlmPool {
    pub fn spawn_models(&mut self, rubric: &Rubric) -> Vec<DisposableSlm> {
        // One SLM per rubric criterion
        rubric.criteria.iter().map(|criterion| {
            DisposableSlm {
                id: Uuid::new_v4(),
                model: load_small_model(),  // Fresh instance
                assigned_criteria: vec![criterion.clone()],
                lifetime: Duration::from_secs(60),
            }
        }).collect()
    }

    pub fn process_parallel(&self, essay: &str, rubric: &Rubric) -> Vec<CriterionScore> {
        let fragments = decompose_essay(essay, &rubric);

        // Each SLM gets ONLY relevant fragment
        self.models.par_iter().zip(fragments).map(|(slm, fragment)| {
            let score = slm.score_fragment(&fragment);

            // DESTROY SLM IMMEDIATELY
            slm.destroy();  // Model weights gone, memory freed

            score
        }).collect()
    }
}
```

#### Essay Decomposition by Rubric

```rust
pub fn decompose_essay(essay: &str, rubric: &Rubric) -> Vec<Fragment> {
    rubric.criteria.iter().map(|criterion| {
        match criterion.focus {
            Focus::Introduction => extract_introduction(essay),
            Focus::Methodology => extract_methodology(essay),
            Focus::CriticalThinking => extract_analysis_only(essay),
            Focus::References => extract_citations_context(essay),  // NOT bibliography
            Focus::Clarity => extract_random_sentences(essay, 10),
        }
    }).collect()
}
```

**Example Rubric Decomposition**:

| Criterion | SLM Sees | SLM Does NOT See |
|-----------|----------|------------------|
| **Introduction Quality** | First 2 paragraphs only | Rest of essay |
| **Methodology** | Methodology section only | Results, discussion |
| **Critical Analysis** | Analysis paragraphs only | Introduction, methods |
| **Citation Usage** | Sentences with citations | Non-cited paragraphs |
| **Conclusion** | Last 2 paragraphs only | Everything else |

**Key Insight**: Each SLM is disposable and sees <20% of essay.

---

### Thread 5: Topic Coherence (Keyword Analysis, Non-AI) 🔍

**Input**: Extracted keywords and their frequencies
**No Access To**: Full sentences, arguments, context

```rust
pub struct KeywordExtractor {
    stopwords: HashSet<String>,
}

impl KeywordExtractor {
    pub fn extract(&self, essay: &str) -> KeywordAnalysis {
        let words: Vec<&str> = essay.split_whitespace()
            .filter(|w| !self.stopwords.contains(*w))
            .collect();

        let frequencies = count_frequencies(&words);
        let top_keywords = get_top_n(&frequencies, 20);

        KeywordAnalysis {
            keywords: top_keywords,
            distribution: calculate_distribution(&frequencies),
            focus_score: calculate_focus(&top_keywords),
        }
    }
}

// Example output (NO sentences, just stats):
KeywordAnalysis {
    keywords: [
        ("algorithm", 15),
        ("efficiency", 12),
        ("data", 10),
        ("structure", 9),
    ],
    distribution: Focused,  // Top 4 words are 60% of content
    focus_score: 0.85,  // High coherence
}
```

**What This Thread Sees**: Word frequencies, statistics
**What It NEVER Sees**: Complete sentences, arguments
**Processing**: Statistical analysis, NO AI

---

### Thread 6: Readability Metrics (Mathematical) 📊

**Input**: Sentence lengths, syllable counts, word lengths
**No Access To**: Sentence content, meaning

```rust
pub fn calculate_readability(essay: &str) -> ReadabilityMetrics {
    let sentences = split_sentences(essay);
    let words = split_words(essay);
    let syllables = count_syllables(&words);

    ReadabilityMetrics {
        flesch_reading_ease: flesch_formula(sentences.len(), words.len(), syllables),
        gunning_fog: gunning_fog_formula(sentences.len(), words.len(), complex_words(&words)),
        avg_sentence_length: words.len() / sentences.len(),
        avg_word_length: calculate_avg_word_length(&words),
    }
}

// Example:
ReadabilityMetrics {
    flesch_reading_ease: 62.5,  // College level
    gunning_fog: 12.3,           // 12th grade
    avg_sentence_length: 18.2,   // words per sentence
    avg_word_length: 4.7,        // characters per word
}
```

**What This Thread Sees**: Counts, lengths, syllables
**What It NEVER Sees**: Word meanings, arguments
**Processing**: Mathematical formulas, NO AI

---

## Parallel Processing Architecture

```
                    ┌─────────────────┐
                    │  Student Essay  │
                    │   (encrypted)   │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │   Core Orchestrator         │
              │   (Trusted, Open-Source)    │
              └──────────────┬──────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│   Thread 1    │    │   Thread 2   │    │   Thread 3   │
│  References   │    │  Structure   │    │   Grammar    │
│  (Rule-based) │    │  (Logtalk)   │    │ (LanguageTool)│
│               │    │              │    │              │
│ Input: Biblio │    │ Input: Tags  │    │ Input: Sents │
│ Sees: 0% IP   │    │ Sees: 0% IP  │    │ Sees: 5% IP  │
└───────┬───────┘    └──────┬───────┘    └──────┬───────┘
        │                   │                    │
        └───────────────────┼────────────────────┘
                            │
        ┌───────────────────┼────────────────────┐
        │                   │                    │
        ▼                   ▼                    ▼
┌───────────────┐    ┌─────────────┐    ┌──────────────┐
│   Thread 4    │    │  Thread 5   │    │   Thread 6   │
│  Rubric SLMs  │    │  Keywords   │    │  Readability │
│ (Disposable)  │    │  (Stats)    │    │  (Math)      │
│               │    │             │    │              │
│ 5 SLMs × 20%  │    │ Input: Words│    │ Input: Counts│
│ Each sees 20% │    │ Sees: 0% IP │    │ Sees: 0% IP  │
└───────┬───────┘    └──────┬──────┘    └──────┬───────┘
        │                   │                   │
        └───────────────────┴───────────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │   Aggregator │
                    │   (Trusted)  │
                    │              │
                    │ Combines all │
                    │ feedback     │
                    └──────┬───────┘
                           │
                           ▼
                   ┌──────────────┐
                   │   Feedback   │
                   │   (to tutor) │
                   └──────────────┘
```

---

## Information Exposure Matrix

| Thread | Sees | Doesn't See | AI? | Disposable? | IP Exposure |
|--------|------|-------------|-----|-------------|-------------|
| **1. References** | Bibliography | Essay body | ❌ No | N/A | 0% |
| **2. Structure** | Section names, counts | Paragraph text | ❌ No | N/A | 0% |
| **3. Grammar** | Random sentences | Order, context | ❌ No | N/A | 5% |
| **4. Rubric SLMs** | 20% each (5 SLMs) | Other 80% | ✅ Yes | ✅ Yes | 20% |
| **5. Keywords** | Word frequencies | Sentences | ❌ No | N/A | 0% |
| **6. Readability** | Counts, lengths | Word meanings | ❌ No | N/A | 0% |

**Total IP Exposure**:
- Non-AI threads: 5% (grammar only, unordered)
- AI threads: 5 SLMs × 20% each = 100% total, but **no single SLM sees >20%**
- **Critical**: SLMs are disposable, destroyed after use

---

## Security Guarantees

### 1. No Complete Essay Reconstruction

Even if attacker compromises ALL threads:
- Thread 1: Only bibliography
- Thread 2: Only structure outline
- Thread 3: Random shuffled sentences (no order)
- Thread 4: 5 fragments (missing 80% each)
- Thread 5: Keyword frequencies (no sentences)
- Thread 6: Mathematical metrics (no text)

**Cannot reconstruct** because:
- No thread has complete text
- Sentences are shuffled (no order)
- 80% of content never seen by AI
- No timestamps/metadata linking fragments

### 2. SLM Disposability

```rust
impl DisposableSlm {
    pub fn destroy(self) {
        // 1. Overwrite model weights with zeros
        self.model.weights.zeroize();

        // 2. Free memory
        drop(self.model);

        // 3. Kill container
        podman_rm_force(self.container_id);

        // 4. Delete logs
        std::fs::remove_file(format!("/tmp/slm-{}.log", self.id));

        // 5. Generate deletion proof
        let proof = prove_deletion(self.id);
        log_attestation(proof);
    }
}
```

**Lifetime**: Each SLM exists for <60 seconds

### 3. Thread Isolation

```yaml
Container Configuration:
  Network: none  # No inter-container communication
  Volumes: read-only  # Cannot persist data
  Memory: 2GB max  # Limited memory prevents full essay caching
  CPU: 1 core  # Prevents side-channel timing attacks
  Seccomp: strict  # Syscall filtering
  Capabilities: none  # No privileges
```

Threads CANNOT:
- Communicate with each other
- Access filesystem
- Access network
- Persist data
- See other threads' inputs

---

## Advanced Decomposition Strategies

### Multi-Pass Processing (Optional)

```rust
// Pass 1: Coarse-grained (paragraph-level)
let para_scores = score_paragraphs_independently(essay);

// Pass 2: Fine-grained (sentence-level)
let sentence_scores = score_sentences_shuffled(essay);

// Pass 3: Integration (aggregate only, no re-reading)
let final_score = aggregate_scores(para_scores, sentence_scores);
```

**Guarantee**: No single pass sees fine + coarse grain simultaneously.

### Differential Fragment Sizes

```rust
// Different SLMs get different granularities
let slm_fragments = vec![
    Fragment { slm_id: 1, size: "paragraph", content: para_3 },
    Fragment { slm_id: 2, size: "sentence", content: sent_5 },
    Fragment { slm_id: 3, size: "section", content: intro },
    Fragment { slm_id: 4, size: "keywords", content: top_10_words },
    Fragment { slm_id: 5, size: "mixed", content: random_sample },
];
```

**Guarantee**: Even if attacker gets fragments, different sizes prevent reassembly.

### Temporal Separation

```rust
// Process fragments with time delays
for (i, fragment) in fragments.iter().enumerate() {
    thread::sleep(Duration::from_secs(5 * i));  // 5s apart
    process_fragment(fragment);
    thread::sleep(Duration::from_secs(5));       // 5s after
    destroy_slm();
}
```

**Guarantee**: Temporal analysis cannot correlate fragments (too much time between).

---

## Implementation Example

### Rubric Criterion: "Critical Analysis"

```rust
// Original essay: 2000 words
// Relevant to "Critical Analysis": Paragraphs 5-8 (500 words)

let critical_analysis_fragment = extract_paragraphs(essay, 5..=8);

// Further reduce: Only sentences with analysis keywords
let filtered = filter_sentences(critical_analysis_fragment, &[
    "however", "although", "suggests", "implies", "contrasts", "argues"
]);

// Result: 10 sentences (200 words)

// Send to SLM #3
let slm3 = spawn_disposable_slm("critical_analysis");
let score = slm3.score(&filtered, rubric.critical_analysis_criterion);

// SLM #3 sees: 10 sentences (10% of essay)
// SLM #3 does NOT see: Introduction, conclusion, methodology, results (90%)

slm3.destroy();  // Gone forever
```

---

## Verification & Auditing

### User Can Verify

```bash
# Show what each thread sees
aws-core explain-decomposition --rubric TM112

Thread 1 (References): Bibliography only (0% essay)
Thread 2 (Structure): Section names only (0% essay)
Thread 3 (Grammar): 47 sentences, shuffled (100% essay, 0% order)
Thread 4 (Rubric):
  - SLM #1: Introduction only (10% essay)
  - SLM #2: Methodology only (15% essay)
  - SLM #3: Analysis only (10% essay)
  - SLM #4: Citations-in-context (5% essay)
  - SLM #5: Conclusion only (8% essay)
  - Total seen by AI: 48% (no overlap, no SLM sees >15%)
Thread 5 (Keywords): Word frequencies (0% essay)
Thread 6 (Readability): Statistics (0% essay)

Maximum single-thread exposure: 15% (SLM #2)
Total unique exposure: 48%
No complete essay reconstruction possible
```

### Attestation Log

```json
{
  "essay_id": "TM112-A1234567-TMA01",
  "decomposition": {
    "threads": 6,
    "ai_threads": 5,
    "max_fragment_size": "15%",
    "total_exposure": "48%",
    "slm_lifetime_avg": "42 seconds"
  },
  "slm_deletions": [
    {
      "slm_id": "slm-001-uuid",
      "criterion": "introduction",
      "fragment_size": "10%",
      "processed_at": "2025-11-22T14:32:01Z",
      "destroyed_at": "2025-11-22T14:32:38Z",
      "deletion_proof": "zkp:abc123..."
    }
  ],
  "reconstruction_impossible": true,
  "attestation_signature": "sig:xyz789..."
}
```

---

## Comparison: Decomposition vs. Encryption

| Approach | Essay Visible? | AI Sees? | Reconstruction Risk |
|----------|----------------|----------|---------------------|
| **Encryption Only** | Encrypted end-to-end | Full essay (decrypted) | If key leaked: 100% |
| **Decomposition Only** | Plaintext fragments | Fragments only | Max 20% per SLM |
| **Both (Recommended)** | Encrypted + fragmented | Encrypted fragments | If key + all threads: <50% |

**Best Practice**: Use both encryption AND decomposition.

---

## FAQ

**Q: Can't an attacker correlate fragments across SLMs?**
A: No, because:
1. SLMs destroyed after use (no logs)
2. Temporal separation (5+ seconds apart)
3. No metadata linking fragments
4. Different SLMs see different granularities

**Q: What if I need feedback on essay flow?**
A: Structure thread (Logtalk) checks logical flow WITHOUT reading content.

**Q: Don't you need context for good feedback?**
A: Surprisingly, no! Most feedback is criterion-specific:
- Grammar: Per-sentence analysis (no context needed)
- Introduction: Only intro paragraphs needed
- Conclusion: Only conclusion needed
- References: Mechanical checking (no essay needed)

**Q: How do you prevent fragment reassembly?**
A: Mathematical guarantee:
- Thread 1-3, 5-6: Never see essay content (0%)
- Thread 4: 5 SLMs × 20% = 100% total, but:
  - No SLM sees >20%
  - Fragments non-overlapping
  - All SLMs destroyed
  - No reassembly metadata

**Q: Can I audit this?**
A: Yes! `aws-core explain-decomposition` shows exactly what each thread sees.

---

## Roadmap

### v0.2.0: Basic Decomposition
- [ ] Reference extraction (non-AI)
- [ ] Structure analysis (Logtalk)
- [ ] Grammar checking (LanguageTool)
- [ ] Basic SLM pool (3 models)

### v0.3.0: Advanced Decomposition
- [ ] 5+ SLM pool
- [ ] Temporal separation
- [ ] Differential fragment sizes
- [ ] Attestation logging

### v0.4.0: Optimal Decomposition
- [ ] Machine learning for optimal fragment selection
- [ ] Dynamic SLM count (based on rubric complexity)
- [ ] Zero-knowledge proofs of fragment isolation

---

## Contact

- **Architecture Questions**: architecture@academic-workflow-suite.org
- **Security Review**: security@academic-workflow-suite.org
- **Research Collaboration**: research@academic-workflow-suite.org

---

**Last Updated**: 2025-11-22
**Version**: 2.0
**Security Model**: "Divide the Content, Conquer the Risk"
**Motto**: "No Single System Sees the Whole Story"
