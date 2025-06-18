;; Basic Fungible Token Contract in Clarity
;; This implements a simple ERC-20 equivalent token

;; Token constants
(define-constant TOKEN_NAME "MyToken")
(define-constant TOKEN_SYMBOL "MTK")
(define-constant DECIMALS u6)
(define-constant TOTAL_SUPPLY u1000000000000) ;; 1 million tokens with 6 decimals

;; Error constants
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_INSUFFICIENT_BALANCE (err u402))
(define-constant ERR_INSUFFICIENT_ALLOWANCE (err u403))
(define-constant ERR_INVALID_AMOUNT (err u404))
(define-constant ERR_INVALID_RECIPIENT (err u405))
(define-constant ERR_OVERFLOW (err u406))

;; Data variables
(define-data-var contract-owner principal tx-sender)

;; Data maps
(define-map balances principal uint)
(define-map allowances {owner: principal, spender: principal} uint)

;; Initialize contract with total supply going to deployer
(map-set balances tx-sender TOTAL_SUPPLY)

;; Read-only functions

;; Get token name
(define-read-only (get-name)
  (ok TOKEN_NAME))

;; Get token symbol
(define-read-only (get-symbol)
  (ok TOKEN_SYMBOL))

;; Get decimals
(define-read-only (get-decimals)
  (ok DECIMALS))

;; Get total supply
(define-read-only (get-total-supply)
  (ok TOTAL_SUPPLY))

;; Get balance of an account
(define-read-only (balance-of (account principal))
  (ok (default-to u0 (map-get? balances account))))

;; Get allowance between owner and spender
(define-read-only (allowance (owner principal) (spender principal))
  (ok (default-to u0 (map-get? allowances {owner: owner, spender: spender}))))

;; Helper function to safely add balances (prevents overflow)
(define-private (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (if (>= result a)
        (some result)
        none)))

;; Helper function to validate recipient address
(define-private (is-valid-recipient (recipient principal))
  (not (is-eq recipient tx-sender)))

;; Public functions

;; Transfer tokens from sender to recipient
(define-public (transfer (recipient principal) (amount uint))
  (let ((sender tx-sender)
        (sender-balance (default-to u0 (map-get? balances sender)))
        (recipient-balance (default-to u0 (map-get? balances recipient))))
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-valid-recipient recipient) ERR_INVALID_RECIPIENT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Check for overflow before updating recipient balance
    (match (safe-add recipient-balance amount)
      success-amount (begin
        ;; Update balances
        (map-set balances sender (- sender-balance amount))
        (map-set balances recipient success-amount)
        
        ;; Emit transfer event
        (print {type: "transfer", from: sender, to: recipient, amount: amount})
        (ok true))
      ERR_OVERFLOW)))

;; Transfer tokens from one account to another (requires allowance)
(define-public (transfer-from (sender principal) (recipient principal) (amount uint))
  (let ((spender tx-sender)
        (sender-balance (default-to u0 (map-get? balances sender)))
        (recipient-balance (default-to u0 (map-get? balances recipient)))
        (current-allowance (default-to u0 (map-get? allowances {owner: sender, spender: spender}))))
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (not (is-eq sender recipient)) ERR_INVALID_RECIPIENT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (>= current-allowance amount) ERR_INSUFFICIENT_ALLOWANCE)
    
    ;; Check for overflow before updating recipient balance
    (match (safe-add recipient-balance amount)
      success-amount (begin
        ;; Update balances and allowance
        (map-set balances sender (- sender-balance amount))
        (map-set balances recipient success-amount)
        (map-set allowances {owner: sender, spender: spender} (- current-allowance amount))
        
        ;; Emit transfer event
        (print {type: "transfer", from: sender, to: recipient, amount: amount})
        (ok true))
      ERR_OVERFLOW)))

;; Approve spender to spend tokens on behalf of owner
(define-public (approve (spender principal) (amount uint))
  (let ((owner tx-sender))
    (asserts! (not (is-eq owner spender)) ERR_INVALID_RECIPIENT)
    (asserts! (>= amount u0) ERR_INVALID_AMOUNT)
    
    ;; Set allowance (amount is validated as non-negative)
    (map-set allowances {owner: owner, spender: spender} amount)
    
    ;; Emit approval event
    (print {type: "approval", owner: owner, spender: spender, amount: amount})
    (ok true)))

;; Mint new tokens (only contract owner)
(define-public (mint (recipient principal) (amount uint))
  (let ((owner (var-get contract-owner))
        (recipient-balance (default-to u0 (map-get? balances recipient))))
    
    (asserts! (is-eq tx-sender owner) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (not (is-eq recipient owner)) ERR_INVALID_RECIPIENT)
    
    ;; Check for overflow before updating recipient balance
    (match (safe-add recipient-balance amount)
      success-amount (begin
        ;; Update recipient balance
        (map-set balances recipient success-amount)
        
        ;; Emit mint event
        (print {type: "mint", to: recipient, amount: amount})
        (ok true))
      ERR_OVERFLOW)))

;; Burn tokens from sender's balance
(define-public (burn (amount uint))
  (let ((sender tx-sender)
        (sender-balance (default-to u0 (map-get? balances sender))))
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Update sender balance
    (map-set balances sender (- sender-balance amount))
    
    ;; Emit burn event
    (print {type: "burn", from: sender, amount: amount})
    (ok true)))

;; Transfer contract ownership (only current owner)
(define-public (transfer-ownership (new-owner principal))
  (let ((current-owner (var-get contract-owner)))
    (asserts! (is-eq tx-sender current-owner) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq current-owner new-owner)) ERR_INVALID_RECIPIENT)
    
    (var-set contract-owner new-owner)
    (print {type: "ownership-transfer", from: current-owner, to: new-owner})
    (ok true)))

;; Increase allowance for spender
(define-public (increase-allowance (spender principal) (amount uint))
  (let ((owner tx-sender)
        (current-allowance (default-to u0 (map-get? allowances {owner: owner, spender: spender}))))
    
    (asserts! (not (is-eq owner spender)) ERR_INVALID_RECIPIENT)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Check for overflow before increasing allowance
    (match (safe-add current-allowance amount)
      new-allowance (begin
        ;; Increase allowance
        (map-set allowances {owner: owner, spender: spender} new-allowance)
        
        ;; Emit approval event
        (print {type: "approval", owner: owner, spender: spender, amount: new-allowance})
        (ok true))
      ERR_OVERFLOW)))

;; Decrease allowance for spender
(define-public (decrease-allowance (spender principal) (amount uint))
  (let ((owner tx-sender)
        (current-allowance (default-to u0 (map-get? allowances {owner: owner, spender: spender}))))
    
    (asserts! (not (is-eq owner spender)) ERR_INVALID_RECIPIENT)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= current-allowance amount) ERR_INSUFFICIENT_ALLOWANCE)
    
    ;; Decrease allowance
    (let ((new-allowance (- current-allowance amount)))
      (map-set allowances {owner: owner, spender: spender} new-allowance)
      
      ;; Emit approval event
      (print {type: "approval", owner: owner, spender: spender, amount: new-allowance})
      (ok true))))

;; Batch transfer to multiple recipients
(define-public (batch-transfer (recipients (list 50 {recipient: principal, amount: uint})))
  (let ((sender tx-sender)
        (sender-balance (default-to u0 (map-get? balances sender)))
        (total-amount (fold + (map get-amount recipients) u0)))
    
    (asserts! (> (len recipients) u0) ERR_INVALID_AMOUNT)
    (asserts! (>= sender-balance total-amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Execute transfers
    (map-set balances sender (- sender-balance total-amount))
    (map execute-transfer recipients)
    
    ;; Emit batch transfer event
    (print {type: "batch-transfer", from: sender, recipients: recipients, total-amount: total-amount})
    (ok true)))

;; Helper function to get amount from recipient tuple
(define-private (get-amount (recipient {recipient: principal, amount: uint}))
  (get amount recipient))

;; Helper function to execute individual transfer in batch
(define-private (execute-transfer (recipient-data {recipient: principal, amount: uint}))
  (let ((recipient (get recipient recipient-data))
        (amount (get amount recipient-data))
        (current-balance (default-to u0 (map-get? balances recipient))))
    
    ;; Validate individual transfer data and use safe addition
    (if (and (> amount u0)
             (is-some (safe-add current-balance amount)))
        (begin
          (map-set balances recipient (unwrap-panic (safe-add current-balance amount)))
          true)
        false)))