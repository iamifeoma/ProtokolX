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

;; Public functions

;; Transfer tokens from sender to recipient
(define-public (transfer (recipient principal) (amount uint))
  (let ((sender tx-sender)
        (sender-balance (default-to u0 (map-get? balances sender))))
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    
    ;; Update balances
    (map-set balances sender (- sender-balance amount))
    (map-set balances recipient (+ (default-to u0 (map-get? balances recipient)) amount))
    
    ;; Emit transfer event (using print for simplicity)
    (print {type: "transfer", from: sender, to: recipient, amount: amount})
    (ok true)))

;; Transfer tokens from one account to another (requires allowance)
(define-public (transfer-from (sender principal) (recipient principal) (amount uint))
  (let ((spender tx-sender)
        (sender-balance (default-to u0 (map-get? balances sender)))
        (current-allowance (default-to u0 (map-get? allowances {owner: sender, spender: spender}))))
    
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (asserts! (>= current-allowance amount) ERR_INSUFFICIENT_ALLOWANCE)
    
    ;; Update balances and allowance
    (map-set balances sender (- sender-balance amount))
    (map-set balances recipient (+ (default-to u0 (map-get? balances recipient)) amount))
    (map-set allowances {owner: sender, spender: spender} (- current-allowance amount))
    
    ;; Emit transfer event
    (print {type: "transfer", from: sender, to: recipient, amount: amount})
    (ok true)))

;; Approve spender to spend tokens on behalf of owner
(define-public (approve (spender principal) (amount uint))
  (let ((owner tx-sender))
    (asserts! (not (is-eq owner spender)) ERR_UNAUTHORIZED)
    
    ;; Set allowance
    (map-set allowances {owner: owner, spender: spender} amount)
    
    ;; Emit approval event
    (print {type: "approval", owner: owner, spender: spender, amount: amount})
    (ok true)))

;; Mint new tokens (only contract owner)
(define-public (mint (recipient principal) (amount uint))
  (let ((owner (var-get contract-owner)))
    (asserts! (is-eq tx-sender owner) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Update recipient balance
    (map-set balances recipient (+ (default-to u0 (map-get? balances recipient)) amount))
    
    ;; Emit mint event
    (print {type: "mint", to: recipient, amount: amount})
    (ok true)))

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
    (var-set contract-owner new-owner)
    (print {type: "ownership-transfer", from: current-owner, to: new-owner})
    (ok true)))

;; Increase allowance for spender
(define-public (increase-allowance (spender principal) (amount uint))
  (let ((owner tx-sender)
        (current-allowance (default-to u0 (map-get? allowances {owner: owner, spender: spender}))))
    
    (asserts! (not (is-eq owner spender)) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Increase allowance
    (map-set allowances {owner: owner, spender: spender} (+ current-allowance amount))
    
    ;; Emit approval event
    (print {type: "approval", owner: owner, spender: spender, amount: (+ current-allowance amount)})
    (ok true)))

;; Decrease allowance for spender
(define-public (decrease-allowance (spender principal) (amount uint))
  (let ((owner tx-sender)
        (current-allowance (default-to u0 (map-get? allowances {owner: owner, spender: spender}))))
    
    (asserts! (not (is-eq owner spender)) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= current-allowance amount) ERR_INSUFFICIENT_ALLOWANCE)
    
    ;; Decrease allowance
    (map-set allowances {owner: owner, spender: spender} (- current-allowance amount))
    
    ;; Emit approval event
    (print {type: "approval", owner: owner, spender: spender, amount: (- current-allowance amount)})
    (ok true)))

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
        (amount (get amount recipient-data)))
    (map-set balances recipient (+ (default-to u0 (map-get? balances recipient)) amount))
    true))