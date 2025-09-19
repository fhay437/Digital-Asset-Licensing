;; Digital Asset Licensing Smart Contract
;; Manages licensing, royalties, and compliance for digital asset innovations

;; Error Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INVALID-ASSET-ID (err u101))
(define-constant ERR-ASSET-NOT-FOUND (err u102))
(define-constant ERR-ASSET-EXPIRED (err u103))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u104))
(define-constant ERR-INVALID-PERCENTAGE (err u105))
(define-constant ERR-ALREADY-EXISTS (err u106))
(define-constant ERR-INVALID-DURATION (err u107))
(define-constant ERR-TRANSFER-FAILED (err u108))
(define-constant ERR-INVALID-PRINCIPAL (err u109))
(define-constant ERR-ASSET-SUSPENDED (err u110))
(define-constant ERR-INVALID-TYPE (err u111))
(define-constant ERR-COMPLIANCE-VIOLATION (err u112))
(define-constant ERR-LIST-FULL (err u113))
(define-constant ERR-INVALID-INPUT (err u114))

;; Validation Constants
(define-constant MIN-ROYALTY-RATE u0)
(define-constant MAX-ROYALTY-RATE u10000) ;; 100% in basis points
(define-constant MIN-ASSET-DURATION u1)
(define-constant MAX-ASSET-DURATION u31536000) ;; 1 year in seconds
(define-constant MIN-ASSET-FEE u1000000) ;; 1 STX in microSTX

;; Contract Constants
(define-constant contract-owner tx-sender)
(define-constant asset-registry-name "digital-asset-licenses")

;; Data Variables
(define-data-var next-asset-id uint u1)
(define-data-var platform-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var compliance-manager principal contract-owner)

;; Asset Types
(define-constant TYPE-RESEARCH u1)
(define-constant TYPE-COMMERCIAL u2)
(define-constant TYPE-EDUCATIONAL u3)
(define-constant TYPE-NON-PROFIT u4)

;; Asset Status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-EXPIRED u2)
(define-constant STATUS-SUSPENDED u3)
(define-constant STATUS-REVOKED u4)

;; Data Maps
(define-map digital-assets
  { asset-id: uint }
  {
    asset-owner: principal,
    licensee: principal,
    content-hash: (string-ascii 64),
    asset-type: uint,
    royalty-rate: uint,
    licensing-fee: uint,
    created-at: uint,
    expires-at: uint,
    status: uint,
    revenue-generated: uint,
    compliance-score: uint
  }
)

(define-map asset-metadata
  { asset-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    technical-specs: (string-ascii 1000),
    usage-terms: (string-ascii 500)
  }
)

(define-map content-assets
  { content-hash: (string-ascii 64) }
  { asset-ids: (list 100 uint) }
)

(define-map user-assets
  { user: principal }
  { owned-assets: (list 100 uint), licensed-assets: (list 100 uint) }
)

(define-map royalty-transactions
  { asset-id: uint, transaction-id: uint }
  {
    payer: principal,
    amount: uint,
    timestamp: uint,
    revenue-reported: uint
  }
)

(define-map compliance-records
  { asset-id: uint, record-id: uint }
  {
    compliance-manager: principal,
    score: uint,
    notes: (string-ascii 500),
    timestamp: uint
  }
)

;; Private Functions

(define-private (is-contract-owner (user principal))
  (is-eq user contract-owner)
)

(define-private (is-compliance-manager (user principal))
  (is-eq user (var-get compliance-manager))
)

(define-private (is-valid-asset-type (asset-type uint))
  (and (>= asset-type TYPE-RESEARCH) (<= asset-type TYPE-NON-PROFIT))
)

(define-private (is-valid-royalty-rate (rate uint))
  (and (>= rate MIN-ROYALTY-RATE) (<= rate MAX-ROYALTY-RATE))
)

(define-private (is-valid-duration (duration uint))
  (and (>= duration MIN-ASSET-DURATION) (<= duration MAX-ASSET-DURATION))
)

(define-private (is-valid-fee (fee uint))
  (>= fee MIN-ASSET-FEE)
)

(define-private (is-valid-string-ascii-64 (input (string-ascii 64)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-100 (input (string-ascii 100)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-500 (input (string-ascii 500)))
  (> (len input) u0)
)

(define-private (is-valid-string-ascii-1000 (input (string-ascii 1000)))
  (> (len input) u0)
)

(define-private (is-valid-asset-id (asset-id uint))
  (and (> asset-id u0) (< asset-id (var-get next-asset-id)))
)

(define-private (is-valid-compliance-score (score uint))
  (<= score u100)
)

(define-private (is-valid-principal (user principal))
  (not (is-eq user 'SP000000000000000000002Q6VF78))
)

(define-private (get-current-time)
  block-height ;; Using block-height as proxy for timestamp
)

(define-private (is-asset-active (asset-data (optional {asset-owner: principal, licensee: principal, content-hash: (string-ascii 64), asset-type: uint, royalty-rate: uint, licensing-fee: uint, created-at: uint, expires-at: uint, status: uint, revenue-generated: uint, compliance-score: uint})))
  (match asset-data
    asset (and 
            (is-eq (get status asset) STATUS-ACTIVE)
            (> (get expires-at asset) (get-current-time)))
    false
  )
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-rate)) u10000)
)

(define-private (calculate-royalty-payment (revenue uint) (royalty-rate uint))
  (/ (* revenue royalty-rate) u10000)
)

(define-private (add-asset-to-content (content-hash (string-ascii 64)) (asset-id uint))
  (let ((current-assets (default-to { asset-ids: (list) } 
                                   (map-get? content-assets { content-hash: content-hash }))))
    (match (as-max-len? (append (get asset-ids current-assets) asset-id) u100)
      updated-list (begin
                     (map-set content-assets 
                              { content-hash: content-hash }
                              { asset-ids: updated-list })
                     (ok true))
      ERR-LIST-FULL
    )
  )
)

(define-private (add-asset-to-user (user principal) (asset-id uint) (is-owner bool))
  (let ((current-data (default-to { owned-assets: (list), licensed-assets: (list) }
                                 (map-get? user-assets { user: user }))))
    (if is-owner
      (match (as-max-len? (append (get owned-assets current-data) asset-id) u100)
        updated-owned (begin
                        (map-set user-assets 
                                 { user: user }
                                 (merge current-data { owned-assets: updated-owned }))
                        (ok true))
        ERR-LIST-FULL)
      (match (as-max-len? (append (get licensed-assets current-data) asset-id) u100)
        updated-licensed (begin
                           (map-set user-assets 
                                    { user: user }
                                    (merge current-data { licensed-assets: updated-licensed }))
                           (ok true))
        ERR-LIST-FULL)
    )
  )
)

;; Read-only Functions

(define-read-only (get-digital-asset (asset-id uint))
  (map-get? digital-assets { asset-id: asset-id })
)

(define-read-only (get-asset-metadata (asset-id uint))
  (map-get? asset-metadata { asset-id: asset-id })
)

(define-read-only (get-content-assets (content-hash (string-ascii 64)))
  (map-get? content-assets { content-hash: content-hash })
)

(define-read-only (get-user-assets (user principal))
  (map-get? user-assets { user: user })
)

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate)
)

(define-read-only (get-next-asset-id)
  (var-get next-asset-id)
)

(define-read-only (is-asset-valid (asset-id uint))
  (let ((asset-data (get-digital-asset asset-id)))
    (is-asset-active asset-data)
  )
)

(define-read-only (calculate-asset-value (asset-id uint))
  (match (get-digital-asset asset-id)
    asset-data (ok {
      base-fee: (get licensing-fee asset-data),
      total-revenue: (get revenue-generated asset-data),
      estimated-royalties: (calculate-royalty-payment 
                           (get revenue-generated asset-data) 
                           (get royalty-rate asset-data))
    })
    ERR-ASSET-NOT-FOUND
  )
)

;; Public Functions

(define-public (create-digital-asset 
                (licensee principal)
                (content-hash (string-ascii 64))
                (asset-type uint)
                (royalty-rate uint)
                (licensing-fee uint)
                (duration uint)
                (title (string-ascii 100))
                (description (string-ascii 500))
                (technical-specs (string-ascii 1000))
                (usage-terms (string-ascii 500)))
  (let ((asset-id (var-get next-asset-id))
        (current-time (get-current-time))
        (expires-at (+ current-time duration)))
    
    ;; Input validation
    (asserts! (is-valid-string-ascii-64 content-hash) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-100 title) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-500 description) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-1000 technical-specs) ERR-INVALID-INPUT)
    (asserts! (is-valid-string-ascii-500 usage-terms) ERR-INVALID-INPUT)
    
    ;; Business logic validation
    (asserts! (is-valid-asset-type asset-type) ERR-INVALID-TYPE)
    (asserts! (is-valid-royalty-rate royalty-rate) ERR-INVALID-PERCENTAGE)
    (asserts! (is-valid-fee licensing-fee) ERR-INSUFFICIENT-PAYMENT)
    (asserts! (is-valid-duration duration) ERR-INVALID-DURATION)
    (asserts! (not (is-eq tx-sender licensee)) ERR-INVALID-PRINCIPAL)
    
    ;; Process payment
    (try! (stx-transfer? licensing-fee tx-sender (as-contract tx-sender)))
    
    ;; Create asset record with validated data
    (map-set digital-assets
             { asset-id: asset-id }
             {
               asset-owner: tx-sender,
               licensee: licensee,
               content-hash: content-hash,
               asset-type: asset-type,
               royalty-rate: royalty-rate,
               licensing-fee: licensing-fee,
               created-at: current-time,
               expires-at: expires-at,
               status: STATUS-ACTIVE,
               revenue-generated: u0,
               compliance-score: u100
             })
    
    ;; Set metadata with validated data
    (map-set asset-metadata
             { asset-id: asset-id }
             {
               title: title,
               description: description,
               technical-specs: technical-specs,
               usage-terms: usage-terms
             })
    
    ;; Update indexes
    (try! (add-asset-to-content content-hash asset-id))
    (try! (add-asset-to-user tx-sender asset-id true))
    (try! (add-asset-to-user licensee asset-id false))
    
    ;; Increment asset ID counter
    (var-set next-asset-id (+ asset-id u1))
    
    (ok asset-id)
  )
)

(define-public (pay-royalty (asset-id uint) (revenue-amount uint))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND))
        (royalty-amount (calculate-royalty-payment revenue-amount (get royalty-rate asset-data)))
        (platform-fee (calculate-platform-fee royalty-amount))
        (owner-payment (- royalty-amount platform-fee)))
    
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    
    ;; Validate asset is active
    (asserts! (is-asset-active (some asset-data)) ERR-ASSET-EXPIRED)
    (asserts! (is-eq tx-sender (get licensee asset-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> royalty-amount u0) ERR-INSUFFICIENT-PAYMENT)
    
    ;; Process payments
    (try! (stx-transfer? owner-payment tx-sender (get asset-owner asset-data)))
    (try! (stx-transfer? platform-fee tx-sender contract-owner))
    
    ;; Update asset revenue
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data 
                   { revenue-generated: (+ (get revenue-generated asset-data) revenue-amount) }))
    
    (ok { royalty-paid: royalty-amount, platform-fee: platform-fee })
  )
)

(define-public (suspend-asset (asset-id uint))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND)))
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    
    (asserts! (or (is-contract-owner tx-sender) 
                  (is-compliance-manager tx-sender)
                  (is-eq tx-sender (get asset-owner asset-data))) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data { status: STATUS-SUSPENDED }))
    
    (ok true)
  )
)

(define-public (reactivate-asset (asset-id uint))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND)))
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    
    (asserts! (is-eq (get status asset-data) STATUS-SUSPENDED) ERR-INVALID-ASSET-ID)
    (asserts! (or (is-contract-owner tx-sender) 
                  (is-compliance-manager tx-sender)
                  (is-eq tx-sender (get asset-owner asset-data))) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (> (get expires-at asset-data) (get-current-time)) ERR-ASSET-EXPIRED)
    
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data { status: STATUS-ACTIVE }))
    
    (ok true)
  )
)

(define-public (update-compliance-score (asset-id uint) (new-score uint) (notes (string-ascii 500)))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND)))
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    (asserts! (is-valid-compliance-score new-score) ERR-INVALID-PERCENTAGE)
    (asserts! (is-valid-string-ascii-500 notes) ERR-INVALID-INPUT)
    
    (asserts! (is-compliance-manager tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    ;; Update asset compliance score
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data { compliance-score: new-score }))
    
    ;; Suspend asset if compliance is too low
    (if (< new-score u50)
      (map-set digital-assets
               { asset-id: asset-id }
               (merge asset-data { status: STATUS-SUSPENDED, compliance-score: new-score }))
      true
    )
    
    (ok true)
  )
)

(define-public (transfer-asset (asset-id uint) (new-licensee principal))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND)))
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    
    (asserts! (is-eq tx-sender (get licensee asset-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-asset-active (some asset-data)) ERR-ASSET-EXPIRED)
    (asserts! (not (is-eq new-licensee (get licensee asset-data))) ERR-INVALID-PRINCIPAL)
    
    ;; Update asset record
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data { licensee: new-licensee }))
    
    ;; Update user indexes
    (try! (add-asset-to-user new-licensee asset-id false))
    
    (ok true)
  )
)

(define-public (extend-asset (asset-id uint) (additional-duration uint))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND))
        (extension-fee (/ (get licensing-fee asset-data) u2))) ;; 50% of original fee
    
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    (asserts! (is-valid-duration additional-duration) ERR-INVALID-DURATION)
    
    (asserts! (is-eq tx-sender (get licensee asset-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-asset-active (some asset-data)) ERR-ASSET-EXPIRED)
    
    ;; Process extension fee
    (try! (stx-transfer? extension-fee tx-sender (get asset-owner asset-data)))
    
    ;; Update expiration
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data 
                   { expires-at: (+ (get expires-at asset-data) additional-duration) }))
    
    (ok true)
  )
)

;; Administrative Functions

(define-public (set-platform-fee-rate (new-rate uint))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-valid-royalty-rate new-rate) ERR-INVALID-PERCENTAGE)
    (var-set platform-fee-rate new-rate)
    (ok true)
  )
)

(define-public (set-compliance-manager (new-manager principal))
  (begin
    (asserts! (is-contract-owner tx-sender) ERR-UNAUTHORIZED-ACCESS)
    ;; Validate the new manager principal is valid
    (asserts! (is-valid-principal new-manager) ERR-INVALID-PRINCIPAL)
    (var-set compliance-manager new-manager)
    (ok true)
  )
)

(define-public (emergency-pause-asset (asset-id uint))
  (let ((asset-data (unwrap! (get-digital-asset asset-id) ERR-ASSET-NOT-FOUND)))
    ;; Input validation
    (asserts! (is-valid-asset-id asset-id) ERR-INVALID-ASSET-ID)
    
    (asserts! (is-contract-owner tx-sender) ERR-UNAUTHORIZED-ACCESS)
    
    (map-set digital-assets
             { asset-id: asset-id }
             (merge asset-data { status: STATUS-REVOKED }))
    
    (ok true)
  )
)