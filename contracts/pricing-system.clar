;; Pricing System Contract
;; Manages dynamic pricing, discounts, and transparent cost calculations

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-PRICE (err u401))
(define-constant ERR-INVALID-DISCOUNT (err u402))
(define-constant ERR-PRICING-RULE-NOT-FOUND (err u403))
(define-constant ERR-INVALID-INPUT (err u404))

;; Pricing factors
(define-constant FACTOR-BASE-PRICE u100)
(define-constant FACTOR-STYLIST-EXPERIENCE u10)
(define-constant FACTOR-PEAK-TIME u20)
(define-constant FACTOR-COMPLEXITY u15)
(define-constant FACTOR-RUSH-SERVICE u25)

;; Data variables
(define-data-var pricing-rule-counter uint u0)

;; Data maps
(define-map pricing-rules uint {
  salon-id: uint,
  service-category: (string-ascii 50),
  base-multiplier: uint,
  experience-bonus: uint,
  peak-time-multiplier: uint,
  complexity-factors: (list 5 uint),
  active: bool,
  created-at: uint
})

(define-map dynamic-pricing uint {
  salon-id: uint,
  service-id: uint,
  time-slot: uint,
  demand-multiplier: uint,
  seasonal-adjustment: uint,
  special-event-multiplier: uint,
  updated-at: uint
})

(define-map discount-codes (string-ascii 20) {
  salon-id: uint,
  discount-percent: uint,
  max-uses: uint,
  current-uses: uint,
  valid-from: uint,
  valid-until: uint,
  active: bool
})

(define-map customer-discounts principal {
  first-time-discount: uint,
  loyalty-discount: uint,
  referral-discount: uint,
  birthday-discount: uint,
  last-updated: uint
})

;; Create pricing rule
(define-public (create-pricing-rule
  (salon-id uint)
  (service-category (string-ascii 50))
  (base-multiplier uint)
  (experience-bonus uint)
  (peak-time-multiplier uint)
  (complexity-factors (list 5 uint)))

  (let ((rule-id (+ (var-get pricing-rule-counter) u1)))

    (asserts! (> base-multiplier u0) ERR-INVALID-PRICE)
    (asserts! (<= base-multiplier u500) ERR-INVALID-PRICE) ;; Max 5x multiplier
    (asserts! (<= experience-bonus u100) ERR-INVALID-PRICE)
    (asserts! (<= peak-time-multiplier u200) ERR-INVALID-PRICE)

    (map-set pricing-rules rule-id {
      salon-id: salon-id,
      service-category: service-category,
      base-multiplier: base-multiplier,
      experience-bonus: experience-bonus,
      peak-time-multiplier: peak-time-multiplier,
      complexity-factors: complexity-factors,
      active: true,
      created-at: block-height
    })

    (var-set pricing-rule-counter rule-id)
    (ok rule-id)
  )
)

;; Calculate service price
(define-public (calculate-service-price
  (salon-id uint)
  (service-id uint)
  (stylist-experience uint)
  (appointment-time uint)
  (complexity-level uint)
  (is-rush bool))

  (let ((base-price u5000) ;; Default base price in cents
        (experience-multiplier (+ u100 (* stylist-experience u5)))
        (time-multiplier (if (is-peak-time appointment-time) u120 u100))
        (complexity-multiplier (+ u100 (* complexity-level u10)))
        (rush-multiplier (if is-rush u150 u100)))

    (asserts! (<= complexity-level u10) ERR-INVALID-INPUT)

    (let ((calculated-price
      (/ (* (* (* (* base-price experience-multiplier) time-multiplier) complexity-multiplier) rush-multiplier)
         u100000000))) ;; Normalize the multipliers

      (ok calculated-price)
    )
  )
)

;; Apply discount code
(define-public (apply-discount-code (code (string-ascii 20)) (original-price uint))
  (let ((discount-info (unwrap! (map-get? discount-codes code) ERR-INVALID-DISCOUNT)))

    (asserts! (get active discount-info) ERR-INVALID-DISCOUNT)
    (asserts! (< (get current-uses discount-info) (get max-uses discount-info)) ERR-INVALID-DISCOUNT)
    (asserts! (>= block-height (get valid-from discount-info)) ERR-INVALID-DISCOUNT)
    (asserts! (<= block-height (get valid-until discount-info)) ERR-INVALID-DISCOUNT)

    (let ((discount-amount (/ (* original-price (get discount-percent discount-info)) u100))
          (final-price (- original-price discount-amount)))

      ;; Update usage count
      (map-set discount-codes code
        (merge discount-info { current-uses: (+ (get current-uses discount-info) u1) }))

      (ok {
        original-price: original-price,
        discount-amount: discount-amount,
        final-price: final-price,
        discount-percent: (get discount-percent discount-info)
      })
    )
  )
)

;; Create discount code
(define-public (create-discount-code
  (code (string-ascii 20))
  (salon-id uint)
  (discount-percent uint)
  (max-uses uint)
  (valid-from uint)
  (valid-until uint))

  (begin
    (asserts! (> (len code) u0) ERR-INVALID-INPUT)
    (asserts! (<= discount-percent u100) ERR-INVALID-DISCOUNT)
    (asserts! (> max-uses u0) ERR-INVALID-INPUT)
    (asserts! (< valid-from valid-until) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? discount-codes code)) ERR-INVALID-DISCOUNT)

    (map-set discount-codes code {
      salon-id: salon-id,
      discount-percent: discount-percent,
      max-uses: max-uses,
      current-uses: u0,
      valid-from: valid-from,
      valid-until: valid-until,
      active: true
    })

    (ok true)
  )
)

;; Set customer discounts
(define-public (set-customer-discounts
  (customer principal)
  (first-time-discount uint)
  (loyalty-discount uint)
  (referral-discount uint)
  (birthday-discount uint))

  (begin
    (asserts! (<= first-time-discount u50) ERR-INVALID-DISCOUNT)
    (asserts! (<= loyalty-discount u30) ERR-INVALID-DISCOUNT)
    (asserts! (<= referral-discount u25) ERR-INVALID-DISCOUNT)
    (asserts! (<= birthday-discount u20) ERR-INVALID-DISCOUNT)

    (map-set customer-discounts customer {
      first-time-discount: first-time-discount,
      loyalty-discount: loyalty-discount,
      referral-discount: referral-discount,
      birthday-discount: birthday-discount,
      last-updated: block-height
    })

    (ok true)
  )
)

;; Helper functions
(define-private (is-peak-time (appointment-time uint))
  ;; Simplified peak time check - would use actual time logic in production
  (> (mod appointment-time u24) u16) ;; After 4 PM
)

;; Read-only functions
(define-read-only (get-pricing-rule (rule-id uint))
  (map-get? pricing-rules rule-id)
)

(define-read-only (get-discount-code (code (string-ascii 20)))
  (map-get? discount-codes code)
)

(define-read-only (get-customer-discounts (customer principal))
  (map-get? customer-discounts customer)
)

(define-read-only (get-pricing-rule-counter)
  (var-get pricing-rule-counter)
)

;; Get price breakdown for transparency
(define-read-only (get-price-breakdown
  (base-price uint)
  (experience-multiplier uint)
  (time-multiplier uint)
  (complexity-multiplier uint)
  (rush-multiplier uint))

  {
    base-price: base-price,
    experience-adjustment: (/ (* base-price (- experience-multiplier u100)) u100),
    time-adjustment: (/ (* base-price (- time-multiplier u100)) u100),
    complexity-adjustment: (/ (* base-price (- complexity-multiplier u100)) u100),
    rush-adjustment: (/ (* base-price (- rush-multiplier u100)) u100)
  }
)
