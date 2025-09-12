(define-fungible-token gift-card)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_TOKEN_EXPIRED (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_BUSINESS_NOT_REGISTERED (err u105))
(define-constant ERR_ALREADY_REGISTERED (err u106))
(define-constant ERR_CARD_NOT_FOUND (err u107))

(define-constant ERR_LISTING_NOT_FOUND (err u200))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u201))
(define-constant ERR_LISTING_EXPIRED (err u202))
(define-constant ERR_NOT_LISTING_OWNER (err u203))
(define-constant ERR_INVALID_PRICE (err u204))


(define-data-var token-name (string-ascii 32) "Gift Card Token")
(define-data-var token-symbol (string-ascii 10) "GIFT")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u0)

(define-map businesses principal {
    name: (string-ascii 50),
    active: bool,
    total-issued: uint
})

(define-map gift-cards uint {
    business: principal,
    recipient: principal,
    amount: uint,
    expiry-block: uint,
    redeemed: uint,
    created-block: uint
})

(define-data-var next-card-id uint u1)

(define-read-only (get-name)
    (ok (var-get token-name))
)

(define-read-only (get-symbol)
    (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
    (ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
    (ok (ft-get-balance gift-card who))
)

(define-read-only (get-total-supply)
    (ok (ft-get-supply gift-card))
)

(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

(define-read-only (get-business (business principal))
    (map-get? businesses business)
)

(define-read-only (get-gift-card (card-id uint))
    (map-get? gift-cards card-id)
)

(define-read-only (is-card-expired (card-id uint))
    (match (map-get? gift-cards card-id)
        card (ok (> stacks-block-height (get expiry-block card)))
        (err ERR_CARD_NOT_FOUND)
    )
)

(define-read-only (get-card-value (card-id uint))
    (match (map-get? gift-cards card-id)
        card (ok (- (get amount card) (get redeemed card)))
        (err ERR_CARD_NOT_FOUND)
    )
)

(define-public (register-business (name (string-ascii 50)))
    (let ((existing (map-get? businesses tx-sender)))
        (if (is-some existing)
            (err ERR_ALREADY_REGISTERED)
            (begin
                (map-set businesses tx-sender {
                    name: name,
                    active: true,
                    total-issued: u0
                })
                (ok true)
            )
        )
    )
)

(define-public (issue-gift-card (recipient principal) (amount uint) (expiry-blocks uint))
    (let (
        (card-id (var-get next-card-id))
        (business-data (unwrap! (map-get? businesses tx-sender) ERR_BUSINESS_NOT_REGISTERED))
        (expiry-block (+ stacks-block-height expiry-blocks))
    )
        (begin
            (asserts! (> amount u0) ERR_INVALID_AMOUNT)
            (asserts! (get active business-data) ERR_BUSINESS_NOT_REGISTERED)
            
            (try! (ft-mint? gift-card amount recipient))
            
            (map-set gift-cards card-id {
                business: tx-sender,
                recipient: recipient,
                amount: amount,
                expiry-block: expiry-block,
                redeemed: u0,
                created-block: stacks-block-height
            })
            
            (map-set businesses tx-sender 
                (merge business-data { total-issued: (+ (get total-issued business-data) u1) })
            )
            
            (var-set next-card-id (+ card-id u1))
            (ok card-id)
        )
    )
)

(define-public (redeem-gift-card (card-id uint) (redeem-amount uint))
    (let (
        (card (unwrap! (map-get? gift-cards card-id) ERR_CARD_NOT_FOUND))
        (available-amount (- (get amount card) (get redeemed card)))
    )
        (begin
            (asserts! (is-eq tx-sender (get recipient card)) ERR_NOT_TOKEN_OWNER)
            (asserts! (<= stacks-block-height (get expiry-block card)) ERR_TOKEN_EXPIRED)
            (asserts! (>= available-amount redeem-amount) ERR_INSUFFICIENT_BALANCE)
            (asserts! (> redeem-amount u0) ERR_INVALID_AMOUNT)
            
            (try! (ft-burn? gift-card redeem-amount tx-sender))
            
            (map-set gift-cards card-id
                (merge card { redeemed: (+ (get redeemed card) redeem-amount) })
            )
            
            (ok redeem-amount)
        )
    )
)

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
    (begin
        (asserts! (or (is-eq tx-sender from) (is-eq contract-caller from)) ERR_NOT_TOKEN_OWNER)
        (ft-transfer? gift-card amount from to)
    )
)

(define-public (deactivate-business)
    (let ((business-data (unwrap! (map-get? businesses tx-sender) ERR_BUSINESS_NOT_REGISTERED)))
        (map-set businesses tx-sender 
            (merge business-data { active: false })
        )
        (ok true)
    )
)

(define-public (reactivate-business)
    (let ((business-data (unwrap! (map-get? businesses tx-sender) ERR_BUSINESS_NOT_REGISTERED)))
        (map-set businesses tx-sender 
            (merge business-data { active: true })
        )
        (ok true)
    )
)

(define-public (extend-card-expiry (card-id uint) (additional-blocks uint))
    (let ((card (unwrap! (map-get? gift-cards card-id) ERR_CARD_NOT_FOUND)))
        (begin
            (asserts! (is-eq tx-sender (get business card)) ERR_NOT_TOKEN_OWNER)
            
            (map-set gift-cards card-id
                (merge card { expiry-block: (+ (get expiry-block card) additional-blocks) })
            )
            (ok true)
        )
    )
)

(define-read-only (get-business-stats (business principal))
    (match (map-get? businesses business)
        data (ok {
            name: (get name data),
            active: (get active data),
            total-issued: (get total-issued data),
            current-block: stacks-block-height
        })
        (err ERR_BUSINESS_NOT_REGISTERED)
    )
)

(define-read-only (get-card-details (card-id uint))
    (match (map-get? gift-cards card-id)
        card (ok {
            business: (get business card),
            recipient: (get recipient card),
            amount: (get amount card),
            redeemed: (get redeemed card),
            remaining: (- (get amount card) (get redeemed card)),
            expiry-block: (get expiry-block card),
            expired: (> stacks-block-height (get expiry-block card)),
            created-block: (get created-block card)
        })
        (err ERR_CARD_NOT_FOUND)
    )
)


(define-map marketplace-listings uint {
    seller: principal,
    card-id: uint,
    price-stx: uint,
    expires-block: uint,
    active: bool
})

(define-data-var next-listing-id uint u1)

(define-read-only (get-listing (listing-id uint))
    (map-get? marketplace-listings listing-id)
)

(define-read-only (is-listing-active (listing-id uint))
    (match (map-get? marketplace-listings listing-id)
        listing (and 
            (get active listing)
            (<= stacks-block-height (get expires-block listing))
        )
        false
    )
)

(define-public (list-card-for-sale (card-id uint) (price-stx uint) (duration-blocks uint))
    (let (
        (card (unwrap! (map-get? gift-cards card-id) ERR_CARD_NOT_FOUND))
        (listing-id (var-get next-listing-id))
        (expires-block (+ stacks-block-height duration-blocks))
    )
        (begin
            (asserts! (is-eq tx-sender (get recipient card)) ERR_NOT_TOKEN_OWNER)
            (asserts! (> price-stx u0) ERR_INVALID_PRICE)
            (asserts! (> (- (get amount card) (get redeemed card)) u0) ERR_INSUFFICIENT_BALANCE)
            (asserts! (<= stacks-block-height (get expiry-block card)) ERR_TOKEN_EXPIRED)
            
            (map-set marketplace-listings listing-id {
                seller: tx-sender,
                card-id: card-id,
                price-stx: price-stx,
                expires-block: expires-block,
                active: true
            })
            
            (var-set next-listing-id (+ listing-id u1))
            (ok listing-id)
        )
    )
)

(define-public (buy-listed-card (listing-id uint))
    (let (
        (listing (unwrap! (map-get? marketplace-listings listing-id) ERR_LISTING_NOT_FOUND))
        (card (unwrap! (map-get? gift-cards (get card-id listing)) ERR_CARD_NOT_FOUND))
        (remaining-value (- (get amount card) (get redeemed card)))
    )
        (begin
            (asserts! (get active listing) ERR_LISTING_NOT_FOUND)
            (asserts! (<= stacks-block-height (get expires-block listing)) ERR_LISTING_EXPIRED)
            (asserts! (<= stacks-block-height (get expiry-block card)) ERR_TOKEN_EXPIRED)
            (asserts! (> remaining-value u0) ERR_INSUFFICIENT_BALANCE)
            
            (try! (stx-transfer? (get price-stx listing) tx-sender (get seller listing)))
            (try! (ft-transfer? gift-card remaining-value (get seller listing) tx-sender))
            
            (map-set gift-cards (get card-id listing)
                (merge card { recipient: tx-sender })
            )
            
            (map-set marketplace-listings listing-id
                (merge listing { active: false })
            )
            
            (ok (get card-id listing))
        )
    )
)

(define-public (cancel-listing (listing-id uint))
    (let ((listing (unwrap! (map-get? marketplace-listings listing-id) ERR_LISTING_NOT_FOUND)))
        (begin
            (asserts! (is-eq tx-sender (get seller listing)) ERR_NOT_LISTING_OWNER)
            
            (map-set marketplace-listings listing-id
                (merge listing { active: false })
            )
            (ok true)
        )
    )
)