@tweaks =
    projectileVelocity: 4
    projectileExplosiveness: 5
    superAmmoExplosiveness: 7

    cannonPosition: [56, 512 - 428]
    cannonSize: [64, 256]   # size of base
    calibre: 6  # thickness of cannon
    cannonLength: 60
    cannonMinAngle: -.3
    cannonMaxAngle: Math.PI / 2

    gravity: -.02
    nextExplosiveness:
        7: 5
        5: 3
        3: 0
        0: 0
    explosionRadius: 3

    ammo: 20
    superAmmoLimit: 10
    ammoR: 0
    ammoG: 0
    ammoB: 0
