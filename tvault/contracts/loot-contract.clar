;; Legendary treasures (bonus multipliers)
(define-map legendary-treasures (string-ascii 50) uint)

;; Initialize some legendary treasure bonuses
(map-set legendary-treasures "Golden Doubloons" u110) ;; 10% bonus
(map-set legendary-treasures "Kraken's Pearl" u125)   ;; 25% bonus
(map-set legendary-treasures "Dragon's Hoard" u150)   ;; 50% bonus
(map-set legendary-treasures "Atlantis Coins" u200)   ;; 100% bonus;; Digital Treasure Chest Contract
;; Pirates can bury their digital treasure and set when it can be discovered

;; Error codes
(define-constant err-not-the-pirate (err u300))
(define-constant err-treasure-still-buried (err u301))
(define-constant err-empty-treasure-chest (err u302))
(define-constant err-invalid-burial-time (err u303))
(define-constant err-chest-not-found (err u304))
(define-constant err-insufficient-treasure (err u305))

;; Contract variables
(define-data-var pirate-king principal tx-sender)

;; Treasure chest structure
(define-map treasure-chests 
  { chest-id: uint }
  {
    pirate-captain: principal,
    treasure-name: (string-ascii 50),
    treasure-amount: uint,
    burial-block: uint,
    discovery-block: uint,
    treasure-map-clue: (string-ascii 200),
    is-cursed: bool
  }
)

;; Global chest counter
(define-data-var next-chest-id uint u1)

;; Get next available chest ID
(define-private (get-next-chest-id)
  (let ((current-id (var-get next-chest-id)))
    (var-set next-chest-id (+ current-id u1))
    current-id
  )
)

;; Bury treasure in a chest
(define-public (bury-treasure 
  (treasure-name (string-ascii 50))
  (treasure-amount uint) 
  (months-until-discovery uint)
  (treasure-map-clue (string-ascii 200))
  (is-cursed bool))
  (let (
    (chest-id (get-next-chest-id))
    (discovery-block (+ block-height (* months-until-discovery u4320))) ;; ~4320 blocks per month
    (minimum-treasure u500000) ;; 0.5 STX minimum
  )
    (asserts! (> treasure-amount minimum-treasure) err-insufficient-treasure)
    (asserts! (> months-until-discovery u0) err-invalid-burial-time)
    
    ;; Transfer treasure to chest
    (try! (stx-transfer? treasure-amount tx-sender (as-contract tx-sender)))
    
    ;; Bury the treasure
    (map-set treasure-chests 
      { chest-id: chest-id }
      {
        pirate-captain: tx-sender,
        treasure-name: treasure-name,
        treasure-amount: treasure-amount,
        burial-block: block-height,
        discovery-block: discovery-block,
        treasure-map-clue: treasure-map-clue,
        is-cursed: is-cursed
      }
    )
    
    (ok { 
      chest-id: chest-id, 
      discovery-block: discovery-block,
      treasure-map-clue: treasure-map-clue 
    })
  )
)

;; Calculate treasure value with bonuses/curses
(define-private (calculate-treasure-value (treasure-name (string-ascii 50)) (base-amount uint) (is-cursed bool) (blocks-buried uint))
  (let (
    (legendary-multiplier (default-to u100 (map-get? legendary-treasures treasure-name)))
    (time-bonus (if (> blocks-buried u21600) u105 u100)) ;; 5% bonus if buried > 5 months
    (curse-penalty (if is-cursed u90 u100)) ;; 10% penalty if cursed
    (total-multiplier (/ (* (* legendary-multiplier time-bonus) curse-penalty) u10000))
  )
    (/ (* base-amount total-multiplier) u100)
  )
)

;; Dig up and claim treasure
(define-public (dig-up-treasure (chest-id uint))
  (let (
    (chest-data (unwrap! (map-get? treasure-chests { chest-id: chest-id }) err-chest-not-found))
    (pirate-captain (get pirate-captain chest-data))
    (treasure-name (get treasure-name chest-data))
    (treasure-amount (get treasure-amount chest-data))
    (burial-block (get burial-block chest-data))
    (discovery-block (get discovery-block chest-data))
    (is-cursed (get is-cursed chest-data))
    (blocks-buried (- block-height burial-block))
    (final-treasure-value (calculate-treasure-value treasure-name treasure-amount is-cursed blocks-buried))
  )
    ;; Verify this is the original pirate
    (asserts! (is-eq tx-sender pirate-captain) err-not-the-pirate)
    
    ;; Check if treasure can be discovered
    (asserts! (>= block-height discovery-block) err-treasure-still-buried)
    
    ;; Transfer treasure with bonuses/penalties
    (try! (as-contract (stx-transfer? final-treasure-value tx-sender pirate-captain)))
    
    ;; Remove the chest (treasure claimed)
    (map-delete treasure-chests { chest-id: chest-id })
    
    (ok { 
      treasure-claimed: final-treasure-value,
      bonus-penalty: (if (> final-treasure-value treasure-amount) 
        (- final-treasure-value treasure-amount) 
        (- treasure-amount final-treasure-value)),
      was-legendary: (is-some (map-get? legendary-treasures treasure-name))
    })
  )
)

;; Peek at treasure chest status
(define-read-only (peek-at-chest (chest-id uint))
  (match (map-get? treasure-chests { chest-id: chest-id })
    chest-data 
    (let (
      (treasure-amount (get treasure-amount chest-data))
      (treasure-name (get treasure-name chest-data))
      (discovery-block (get discovery-block chest-data))
      (burial-block (get burial-block chest-data))
      (is-cursed (get is-cursed chest-data))
      (is-discoverable (>= block-height discovery-block))
      (blocks-buried (- block-height burial-block))
      (projected-value (calculate-treasure-value treasure-name treasure-amount is-cursed blocks-buried))
    )
      (ok {
        chest-info: chest-data,
        is-discoverable: is-discoverable,
        blocks-until-discovery: (if is-discoverable u0 (- discovery-block block-height)),
        projected-treasure-value: projected-value
      })
    )
    err-chest-not-found
  )
)

;; Get treasure chest details
(define-read-only (get-chest-details (chest-id uint))
  (map-get? treasure-chests { chest-id: chest-id })
)

;; Abandon treasure chest (emergency escape with penalty)
(define-public (abandon-treasure-chest (chest-id uint))
  (let (
    (chest-data (unwrap! (map-get? treasure-chests { chest-id: chest-id }) err-chest-not-found))
    (pirate-captain (get pirate-captain chest-data))
    (treasure-amount (get treasure-amount chest-data))
    (abandonment-penalty (/ treasure-amount u5)) ;; 20% penalty for abandoning
    (recovery-amount (- treasure-amount abandonment-penalty))
  )
    ;; Verify ownership
    (asserts! (is-eq tx-sender pirate-captain) err-not-the-pirate)
    
    ;; Transfer reduced amount
    (try! (as-contract (stx-transfer? recovery-amount tx-sender pirate-captain)))
    
    ;; Remove chest
    (map-delete treasure-chests { chest-id: chest-id })
    
    (ok { 
      recovered-treasure: recovery-amount, 
      penalty-paid: abandonment-penalty 
    })
  )
)

;; Check if treasure is legendary
(define-read-only (is-legendary-treasure (treasure-name (string-ascii 50)))
  (is-some (map-get? legendary-treasures treasure-name))
)

;; Get legendary treasure multiplier
(define-read-only (get-legendary-multiplier (treasure-name (string-ascii 50)))
  (map-get? legendary-treasures treasure-name)
)