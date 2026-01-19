(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))

(define-map final-invoices
  { contract-id: uint }
  {
    vendor-id: principal,
    invoice-amount: uint,
    reconciliation-status: (string-ascii 20),
    reconciled-date: uint,
    variance-amount: uint
  }
)

(define-map documentation-assembly
  { doc-id: uint }
  {
    contract-id: uint,
    document-type: (string-ascii 50),
    file-hash: (string-ascii 100),
    submission-date: uint,
    verification-status: (string-ascii 20)
  }
)

(define-map regulatory-compliance
  { compliance-id: uint }
  {
    contract-id: uint,
    requirement-type: (string-ascii 100),
    compliance-status: (string-ascii 20),
    completion-date: uint,
    documentation-provided: bool
  }
)

(define-map audit-preparation
  { audit-id: uint }
  {
    contract-id: uint,
    audit-readiness-score: uint,
    missing-items-count: uint,
    scheduled-audit-date: uint,
    preparation-status: (string-ascii 20)
  }
)

(define-data-var next-contract-id uint u1)
(define-data-var next-doc-id uint u1)
(define-data-var next-compliance-id uint u1)
(define-data-var next-audit-id uint u1)

(define-public (submit-final-invoice (vendor-id principal) (amount uint))
  (let ((contract-id (var-get next-contract-id)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (map-set final-invoices
        { contract-id: contract-id }
        {
          vendor-id: vendor-id,
          invoice-amount: amount,
          reconciliation-status: "pending",
          reconciled-date: u0,
          variance-amount: u0
        }
      )
      (var-set next-contract-id (+ contract-id u1))
      (ok contract-id)
    )
  )
)

(define-public (reconcile-invoice (contract-id uint) (variance uint))
  (let ((invoice (map-get? final-invoices { contract-id: contract-id })))
    (if (is-some invoice)
      (let ((current (unwrap-panic invoice)))
        (begin
          (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
          (map-set final-invoices
            { contract-id: contract-id }
            (merge current {
              reconciliation-status: "reconciled",
              reconciled-date: u0,
              variance-amount: variance
            })
          )
          (ok true)
        )
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (submit-document (contract-id uint) (doc-type (string-ascii 50)) (file-hash (string-ascii 100)))
  (let ((doc-id (var-get next-doc-id)))
    (begin
      (map-set documentation-assembly
        { doc-id: doc-id }
        {
          contract-id: contract-id,
          document-type: doc-type,
          file-hash: file-hash,
          submission-date: u0,
          verification-status: "submitted"
        }
      )
      (var-set next-doc-id (+ doc-id u1))
      (ok doc-id)
    )
  )
)

(define-public (verify-compliance (contract-id uint) (requirement (string-ascii 100)) (has-docs bool))
  (let ((compliance-id (var-get next-compliance-id)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (map-set regulatory-compliance
        { compliance-id: compliance-id }
        {
          contract-id: contract-id,
          requirement-type: requirement,
          compliance-status: (if has-docs "compliant" "non-compliant"),
          completion-date: u0,
          documentation-provided: has-docs
        }
      )
      (var-set next-compliance-id (+ compliance-id u1))
      (ok compliance-id)
    )
  )
)

(define-public (prepare-audit (contract-id uint) (readiness-score uint) (missing-items uint) (audit-date uint))
  (let ((audit-id (var-get next-audit-id)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (map-set audit-preparation
        { audit-id: audit-id }
        {
          contract-id: contract-id,
          audit-readiness-score: readiness-score,
          missing-items-count: missing-items,
          scheduled-audit-date: audit-date,
          preparation-status: "ready"
        }
      )
      (var-set next-audit-id (+ audit-id u1))
      (ok audit-id)
    )
  )
)

(define-read-only (get-invoice (contract-id uint))
  (map-get? final-invoices { contract-id: contract-id })
)

(define-read-only (get-compliance (compliance-id uint))
  (map-get? regulatory-compliance { compliance-id: compliance-id })
)

(define-read-only (get-audit-status (audit-id uint))
  (map-get? audit-preparation { audit-id: audit-id })
)

