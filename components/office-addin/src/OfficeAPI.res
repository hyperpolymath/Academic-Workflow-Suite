// Office.js API bindings for ReScript

// External bindings to Office.js global objects
@val @scope("Office")
external onReady: (. unit => unit) => unit = "onReady"

@val @scope("Office") @scope("context") @scope("document")
external getSelectedDataAsync: (. string, {..}, (. {..}) => unit) => unit = "getSelectedDataAsync"

@val @scope("Office") @scope("context") @scope("document")
external setSelectedDataAsync: (. string, {..}, (. {..}) => unit) => unit = "setSelectedDataAsync"

@val @scope("Office") @scope("context") @scope("document")
external getFileAsync: (. int, {..}, (. {..}) => unit) => unit = "getFileAsync"

@val @scope("Office") @scope("context")
external displayDialogAsync: (. string, {..}, (. {..}) => unit) => unit = "displayDialogAsync"

// Constants for coercion types
module CoercionType = {
  @val @scope(("Office", "CoercionType")) external text: string = "Text"
  @val @scope(("Office", "CoercionType")) external html: string = "Html"
  @val @scope(("Office", "CoercionType")) external matrix: string = "Matrix"
  @val @scope(("Office", "CoercionType")) external table: string = "Table"
}

// Constants for async result status
module AsyncResultStatus = {
  @val @scope(("Office", "AsyncResultStatus")) external succeeded: string = "Succeeded"
  @val @scope(("Office", "AsyncResultStatus")) external failed: string = "Failed"
}

// Helper to convert Types.Office.coercionType to string
let coercionTypeToString = (ct: Types.Office.coercionType) =>
  switch ct {
  | Text => CoercionType.text
  | Html => CoercionType.html
  | Matrix => CoercionType.matrix
  | Table => CoercionType.table
  }

// Safe wrapper for getSelectedDataAsync
let getSelectedData = async (coercionType: Types.Office.coercionType): result<string, string> => {
  try {
    let promise = Promise.make((resolve, _reject) => {
      let options = {"coercionType": coercionTypeToString(coercionType)}

      getSelectedDataAsync(. CoercionType.text, options, (. asyncResult) => {
        let status = asyncResult["status"]

        if status === AsyncResultStatus.succeeded {
          let value = asyncResult["value"]
          switch value {
          | Some(v) => resolve(Ok(v))
          | None => resolve(Error("No data selected"))
          }
        } else {
          let error = asyncResult["error"]
          let errorMsg = switch error {
          | Some(err) => err["message"]
          | None => "Unknown error occurred"
          }
          resolve(Error(errorMsg))
        }
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to get selected data")
      Error(message)
    }
  | _ => Error("Unexpected error in getSelectedData")
  }
}

// Safe wrapper for setSelectedDataAsync
let setSelectedData = async (data: string, coercionType: Types.Office.coercionType): result<
  unit,
  string,
> => {
  try {
    let promise = Promise.make((resolve, _reject) => {
      let options = {"coercionType": coercionTypeToString(coercionType)}

      setSelectedDataAsync(. data, options, (. asyncResult) => {
        let status = asyncResult["status"]

        if status === AsyncResultStatus.succeeded {
          resolve(Ok())
        } else {
          let error = asyncResult["error"]
          let errorMsg = switch error {
          | Some(err) => err["message"]
          | None => "Unknown error occurred"
          }
          resolve(Error(errorMsg))
        }
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to set selected data")
      Error(message)
    }
  | _ => Error("Unexpected error in setSelectedData")
  }
}

// Get entire document content
let getDocumentContent = async (): result<string, string> => {
  try {
    // For Word, we'll use the Word API to get the whole document
    // This is a simplified version - real implementation would use Word.run
    let promise = Promise.make((resolve, _reject) => {
      // Fallback: ask user to select all content
      let options = {"coercionType": CoercionType.text}

      getSelectedDataAsync(. CoercionType.text, options, (. asyncResult) => {
        let status = asyncResult["status"]

        if status === AsyncResultStatus.succeeded {
          let value = asyncResult["value"]
          switch value {
          | Some(v) => resolve(Ok(v))
          | None => resolve(Error("No content found"))
          }
        } else {
          resolve(Error("Please select the content you want to process"))
        }
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to get document content")
      Error(message)
    }
  | _ => Error("Unexpected error in getDocumentContent")
  }
}

// Insert text at current position
let insertText = async (text: string): result<unit, string> => {
  await setSelectedData(text, Text)
}

// Insert HTML at current position
let insertHtml = async (html: string): result<unit, string> => {
  await setSelectedData(html, Html)
}

// Show notification to user
@val @scope(("Office", "context", "ui"))
external displayDialogAsyncRaw: (. string, {..}, (. {..}) => unit) => unit = "displayDialogAsync"

let showNotification = (title: string, message: string): unit => {
  // Office.js doesn't have built-in notifications for Word
  // We'll use console.log for now, or implement a custom dialog
  Js.Console.log2(title, message)
}

// Initialize Office.js
let initialize = async (): result<unit, string> => {
  try {
    let promise = Promise.make((resolve, _reject) => {
      onReady(. () => {
        resolve(Ok())
      })
    })

    await promise
  } catch {
  | Js.Exn.Error(err) => {
      let message = Js.Exn.message(err)->Option.getOr("Failed to initialize Office.js")
      Error(message)
    }
  | _ => Error("Unexpected error in Office.js initialization")
  }
}

// Check if running in Office context
@val @scope("Office")
external context: {..} = "context"

let isOfficeContext = (): bool => {
  try {
    let _ = context
    true
  } catch {
  | _ => false
  }
}

// Get host info
@val @scope(("Office", "context"))
external host: {..} = "host"

type hostType = Word | Excel | PowerPoint | Outlook | Unknown

let getHostType = (): hostType => {
  try {
    let hostName = host["type"]
    switch hostName {
    | "Word" => Word
    | "Excel" => Excel
    | "PowerPoint" => PowerPoint
    | "Outlook" => Outlook
    | _ => Unknown
    }
  } catch {
  | _ => Unknown
  }
}

// Event handlers
type eventHandler = unit => unit

let onSelectionChanged = (handler: eventHandler): unit => {
  // Office.context.document.addHandlerAsync would be used here
  // Simplified for now
  let _ = handler
  ()
}

// ============================================================================
// Word-specific API bindings (Word.run context)
// ============================================================================

module Word = {
  // Word.run() context binding
  @val @scope("Word")
  external run: (. {..} => promise<unit>) => promise<unit> = "run"

  // Document body type
  type body = {
    insertText: (. string, string) => unit,
    insertHtml: (. string, string) => unit,
    clear: (. unit) => unit,
    getText: (. unit) => string,
  }

  // Range type
  type range = {
    insertText: (. string, string) => unit,
    insertComment: (. string) => unit,
    select: (. string) => unit,
  }

  // Comment type
  type comment = {
    content: string,
    resolved: bool,
  }

  // Content control type
  type contentControl = {
    tag: string,
    title: string,
    insertText: (. string, string) => unit,
    delete: (. bool) => unit,
  }

  // Document type
  type document = {
    body: body,
    getSelection: (. unit) => range,
    contentControls: {
      getByTag: (. string) => array<contentControl>,
      add: (. string, range) => contentControl,
    },
    properties: {
      customProperties: {
        add: (. string, string) => unit,
        getItem: (. string) => {..},
        deleteAll: (. unit) => unit,
      },
    },
  }

  // Context type
  type context = {
    document: document,
    sync: (. unit) => promise<unit>,
    load: (. {..}, string) => unit,
  }

  // Insert positions
  @val @scope(("Word", "InsertLocation"))
  external before: string = "Before"

  @val @scope(("Word", "InsertLocation"))
  external after: string = "After"

  @val @scope(("Word", "InsertLocation"))
  external start: string = "Start"

  @val @scope(("Word", "InsertLocation"))
  external end_: string = "End"

  @val @scope(("Word", "InsertLocation"))
  external replace: string = "Replace"

  // Get full document text using Word.run()
  let getDocumentText = async (): result<string, string> => {
    try {
      let textRef = ref("")

      await run(. async context => {
        let doc = context["document"]
        let body = doc["body"]
        context["load"](. body, "text")
        await context["sync"](.)
        textRef := body["text"]
      })

      Ok(textRef.contents)
    } catch {
    | Js.Exn.Error(err) =>
      Error(Js.Exn.message(err)->Option.getOr("Failed to get document text"))
    | _ => Error("Unexpected error getting document text")
    }
  }

  // Insert feedback as comment at current selection
  let insertFeedbackComment = async (feedbackText: string): result<unit, string> => {
    try {
      await run(. async context => {
        let range = context["document"]["getSelection"](.)
        range["insertComment"](. feedbackText)
        await context["sync"](.)
      })

      Ok()
    } catch {
    | Js.Exn.Error(err) =>
      Error(Js.Exn.message(err)->Option.getOr("Failed to insert comment"))
    | _ => Error("Unexpected error inserting comment")
    }
  }

  // Insert formatted feedback at end of document
  let appendFormattedFeedback = async (
    feedback: string,
    score: option<float>,
  ): result<unit, string> => {
    try {
      await run(. async context => {
        let body = context["document"]["body"]

        // Build feedback HTML
        let scoreHtml = switch score {
        | Some(s) => `<p><strong>Score:</strong> ${Float.toString(s)}</p>`
        | None => ""
        }

        let html = `
          <div style="border-top: 2px solid #0078d4; margin-top: 20px; padding-top: 10px;">
            <h2 style="color: #0078d4;">Feedback</h2>
            ${scoreHtml}
            <div style="background: #f5f5f5; padding: 15px; border-left: 4px solid #0078d4;">
              ${feedback}
            </div>
          </div>
        `

        body["insertHtml"](. html, end_)
        await context["sync"](.)
      })

      Ok()
    } catch {
    | Js.Exn.Error(err) =>
      Error(Js.Exn.message(err)->Option.getOr("Failed to append feedback"))
    | _ => Error("Unexpected error appending feedback")
    }
  }

  // Get student ID from custom document properties
  let getStudentId = async (): result<option<string>, string> => {
    try {
      let studentIdRef = ref(None)

      await run(. async context => {
        let props = context["document"]["properties"]["customProperties"]
        try {
          let studentIdProp = props["getItem"](. "StudentID")
          context["load"](. studentIdProp, "value")
          await context["sync"](.)
          studentIdRef := Some(studentIdProp["value"])
        } catch {
        | _ => studentIdRef := None
        }
      })

      Ok(studentIdRef.contents)
    } catch {
    | Js.Exn.Error(err) =>
      Error(Js.Exn.message(err)->Option.getOr("Failed to get student ID"))
    | _ => Error("Unexpected error getting student ID")
    }
  }

  // Set student ID in custom document properties
  let setStudentId = async (studentId: string): result<unit, string> => {
    try {
      await run(. async context => {
        let props = context["document"]["properties"]["customProperties"]

        // Delete existing StudentID property if it exists
        try {
          let existing = props["getItem"](. "StudentID")
          existing["delete"](.)
        } catch {
        | _ => ()
        }

        // Add new StudentID property
        props["add"](. "StudentID", studentId)
        await context["sync"](.)
      })

      Ok()
    } catch {
    | Js.Exn.Error(err) =>
      Error(Js.Exn.message(err)->Option.getOr("Failed to set student ID"))
    | _ => Error("Unexpected error setting student ID")
    }
  }

  // Extract student ID from document text (fallback if not in properties)
  let extractStudentIdFromText = (text: string): option<string> => {
    // Look for patterns like "Student ID: A1234567" or just "A1234567"
    let patterns = [
      %re("/Student ID:\s*([A-Z]\d{7})/i"),
      %re("/ID:\s*([A-Z]\d{7})/i"),
      %re("/\b([A-Z]\d{7})\b/"),
    ]

    let rec tryPatterns = (patterns: array<Js.Re.t>): option<string> => {
      switch patterns {
      | [] => None
      | [pattern, ...rest] =>
        switch Js.Re.exec_(pattern, text) {
        | Some(result) =>
          switch Js.Re.captures(result)[1] {
          | Some(id) => Some(id)
          | None => tryPatterns(rest)
          }
        | None => tryPatterns(rest)
        }
      }
    }

    tryPatterns(patterns)
  }

  // Get or extract student ID (tries properties first, then text extraction)
  let getOrExtractStudentId = async (): result<option<string>, string> => {
    // Try getting from properties first
    let propResult = await getStudentId()

    switch propResult {
    | Ok(Some(id)) => Ok(Some(id))
    | Ok(None) | Error(_) => {
        // Fallback: extract from document text
        let textResult = await getDocumentText()
        switch textResult {
        | Ok(text) => Ok(extractStudentIdFromText(text))
        | Error(e) => Error(e)
        }
      }
    }
  }

  // Insert content control for feedback section
  let insertFeedbackContentControl = async (tag: string, title: string): result<
    unit,
    string,
  > => {
    try {
      await run(. async context => {
        let range = context["document"]["getSelection"](.)
        let _ = context["document"]["contentControls"]["add"](. tag, range)
        // Set title would go here if we had the API binding
        await context["sync"](.)
      })

      Ok()
    } catch {
    | Js.Exn.Error(err) =>
      Error(Js.Exn.message(err)->Option.getOr("Failed to insert content control"))
    | _ => Error("Unexpected error inserting content control")
    }
  }
}
